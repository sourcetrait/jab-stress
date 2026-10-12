# The checkout runner's guards, which its recovery shares: a run's mark,
# the sweep that ends every marked process, the atomic write, the staged
# files left in a checkout, and the cancel no catch may swallow. Import it
# by its absolute path, `use <checkout>/runners/guard.nu [...]`.
#
# A run's processes carry the variable MARK, `<call>:<mutant>`, which each
# inherits whatever process group it moves to, so a process a nested
# `timeout` keeps out of the outer one's group is found all the same. A
# process the host has adopted and that has since exited stays a zombie,
# state Z, its environment unreadable; it counts as gone.
#
# The Grammar MCP cancels a call, at its `timeout_ms` or by `kill`, by
# setting the body's interrupt flag and sending SIGKILL to each external
# the body started and their descendants; the body is not stopped. A
# `try` that catches the interrupt, or an external a signal ended, clears
# the flag, and the body then runs on with no caller, so every catch here
# raises such an error again, and a cancelled call stops where the cancel
# finds it.

# The variable that marks a run's processes.
export const MARK = "JAB_RUNNER_MARK"

# The infix of a staged file's name, `.<name>.jabstage.<call>`.
export const STAGE = ".jabstage."

# Whether a caught error is a cancel's: nushell's interrupt, or an external
# a signal ended.
export def cancel-class [e: record]: nothing -> bool {
    ($e.debug? | default "" | str starts-with "Interrupted") or ($e.details?.code? == "nu::shell::terminated_by_signal")
}

# A caught error a cancel caused raised again, so the catch does not
# swallow the call's cancel; any other error passes.
export def raise-cancel [e: record] {
    if (cancel-class $e) { error make {msg: $"cancelled: ($e.msg)"} }
}

# A process's state and group from `<proc>/<pid>/stat`, null for none.
export def proc-stat [proc: string, pid: int] {
    let s = (try { open --raw ($proc | path join ($pid | into string) "stat") | into binary | decode } catch {|e| raise-cancel $e; "" })
    if $s == "" { return null }
    let start = (($s | str index-of ")" --end) + 2)
    let fields = ($s | str substring $start.. | split row " ")
    { state: ($fields | get 0), pgid: ($fields | get 2 | into int) }
}

# Whether a process lives: present and no zombie.
export def live [proc: string, pid: int]: nothing -> bool {
    let st = (proc-stat $proc $pid)
    $st != null and $st.state != "Z"
}

# Every live process whose mark starts with `prefix`: its pid, its group,
# whether it leads that group, its command line, and its mark.
export def marked [proc: string, prefix: string]: nothing -> list<record<pid: int, pgid: int, leads: bool, cmd: string, mark: string>> {
    let nul = (char --unicode "0")
    let cut = (($MARK | str length) + 1)
    mut found = []
    for b in (ls $proc | get name | each {|p| $p | path basename } | where {|b| $b =~ '^\d+$' }) {
        let pid = ($b | into int)
        let env_text = (try { open --raw ($proc | path join $b "environ") | into binary | decode } catch {|e| raise-cancel $e; "" })
        let hit = ($env_text | split row $nul | where {|kv| $kv | str starts-with $"($MARK)=($prefix)" })
        if not ($hit | is-empty) {
            let st = (proc-stat $proc $pid)
            if $st != null and $st.state != "Z" {
                let cmd = (try { open --raw ($proc | path join $b "cmdline") | into binary | decode | str replace --all $nul " " | str trim } catch {|e| raise-cancel $e; "" })
                $found = ($found | append { pid: $pid, pgid: $st.pgid, leads: ($st.pgid == $pid), cmd: ($cmd | str substring -g 0..<160), mark: ($hit | first | str substring $cut..) })
            }
        }
    }
    $found
}

# Every live process whose mark starts with `prefix` ended: TERM to each
# and to each group one of them leads, up to `wait` for them to go, then
# KILL to any left and `wait` again. Never the host's pid or its group,
# never pid 1, nothing unmarked. The record: each process found with the
# signals sent to it and when, and when it was observed gone, seconds
# from `origin`, null for one never seen gone; `left`, the pids still
# live. Which signal ended a process is no part of it: a disappearance
# after a signal shows the signal was sent, not that it ended the process.
export def sweep [proc: string, prefix: string, host_pid: int, host_pgid: int, origin: datetime, wait: duration] {
    let found = (marked $proc $prefix)
    if ($found | is-empty) { return { records: [], left: [] } }
    mut sent = []
    mut gone = []
    for sig in ["TERM" "KILL"] {
        let done = ($gone | each {|g| $g.pid })
        let targets = ($found | where {|f| $f.pid not-in $done })
        if ($targets | is-empty) { break }
        let at = (((date now) - $origin) / 1sec | into float | math round --precision 3)
        for f in $targets {
            if $f.leads and $f.pgid != $host_pgid and $f.pgid > 1 {
                ^kill -s $sig -- $"-($f.pgid)" | complete | ignore
            }
            if $f.pid != $host_pid and $f.pid > 1 {
                ^kill -s $sig $f.pid | complete | ignore
            }
            $sent = ($sent | append { pid: $f.pid, signal: $sig, at: $at })
        }
        let until = ((date now) + $wait)
        mut waiting = true
        while $waiting {
            let seen = ($gone | each {|g| $g.pid })
            for f in ($targets | where {|t| $t.pid not-in $seen }) {
                if not (live $proc $f.pid) {
                    $gone = ($gone | append { pid: $f.pid, at: (((date now) - $origin) / 1sec | into float | math round --precision 3) })
                }
            }
            let seen_now = ($gone | each {|g| $g.pid })
            if ($targets | all {|t| $t.pid in $seen_now }) or ((date now) > $until) {
                $waiting = false
            } else {
                sleep 50ms
            }
        }
    }
    let sent_all = $sent
    let gone_all = $gone
    let gone_pids = ($gone_all | each {|g| $g.pid })
    {
        records: ($found | each {|f| $f | merge { signals: ($sent_all | where pid == $f.pid | select signal at), gone_at: ($gone_all | where pid == $f.pid | get -o 0.at) } }),
        left: ($found | where {|f| $f.pid not-in $gone_pids } | each {|f| $f.pid }),
    }
}

# Every staged file in the checkout at `root`, ignored files included,
# its path relative to `root`: the staging of call `call`, or of any call
# for "".
export def strays [root: string, call: string]: nothing -> list<string> {
    let tail = (if $call == "" { "*" } else { $call })
    let spec = (":(glob)**/*" + $STAGE + $tail)
    ^git -C $root ls-files --others -z -- $spec | split row (char --unicode "0") | where {|p| $p != "" }
}

# `bytes` staged beside `dest` as `.<name>.jabstage.<call>`, given dest's
# mode, held to `hash`; the staged path back. A staged path already
# present is refused, never overwritten.
export def stage [dest: string, bytes: binary, hash: string, call: string] {
    let staged = ($dest | path dirname | path join $".($dest | path basename)($STAGE)($call)")
    if ($staged | path type) != null { error make {msg: $"($staged) exists; a staged file is never overwritten"} }
    $bytes | save --raw $staged
    ^chmod --reference $dest $staged
    let got = (open --raw $staged | into binary | hash sha256)
    if $got != $hash { error make {msg: $"($staged): staged ($got), where ($hash) was meant"} }
    $staged
}

# A staged file renamed onto `dest` (rename(2) within one directory, the
# name replaced whole), which must then be the staged file, its inode, and
# hold `hash`.
export def land [staged: string, dest: string, hash: string] {
    let inode = (ls -l $staged | get 0.inode)
    mv -f $staged $dest
    let now = (ls -l $dest | get 0.inode)
    if $now != $inode { error make {msg: $"($dest): inode ($now) after the rename, where the staged file's ($inode) was meant"} }
    let got = (open --raw $dest | into binary | hash sha256)
    if $got != $hash { error make {msg: $"($dest): ($got) after the rename, where ($hash) was meant"} }
}
