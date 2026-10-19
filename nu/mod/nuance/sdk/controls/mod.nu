use (path self ../../../../../../jab/nu/mod/sdl)
use (path self ../../../../../../jab/nu/mod/build)

# This module's directory, in the workbench's checkout
const HERE = (path self | path dirname)

# jab, checked out beside the workbench
const JAB = (path self ../../../../../../jab | path expand)

# Each control's probe run, in seconds
const SECONDS = 12

# The window's switches a run makes, as measured
const SWITCHES = 3

# The console's own uploads a run makes, as measured
const CONSOLE = 2

# QEMU's trace words for the device's flushes and set_scanouts
const TRACE = "-msg timestamp=on -trace virtio_gpu_cmd_res_flush -trace virtio_gpu_cmd_set_scanout"

# The system's QEMU, whose virtio-gpu may be a module
const SYSTEM_QEMU = "/usr/bin/qemu-system-riscv64"

# The system's install prefix, linked for the modular control
const SYSTEM_PREFIX = "/usr"

# Where a system's QEMU keeps its modules
const MODULE_DIRS = ["/usr/lib64/qemu" "/usr/lib/qemu" "/usr/lib/x86_64-linux-gnu/qemu"]

# The console's update functions a second frame names
const CONSOLE_UPDATES = ["qemu_console_update" "qemu_console_update_full" "dpy_gfx_update" "dpy_gfx_update_full"]

# One probe run, its exit, record, stderr, and the shim log it wrote
def probe-run [name: string, program: string, out: path, qemu_args: string]: nothing -> record<exit: int, record: oneof<record, nothing>, stderr: string, log: string> {
    let tool = ($JAB | path join "nu" "bin" "nuance" "probe.nu")
    let log = (build program-out ($JAB | path join $program) "release" | path join "probe" "sdl.log")
    let state = {|| if ($log | path type) == null { null } else { ls -l $log | get 0 | select inode size modified } }
    let before = (do $state)
    let ran = (with-env { JAB_QEMU_ARGS: $qemu_args } { ^$nu.current-exe $tool sdl $program --seconds ($SECONDS | into string) | complete })
    $ran.stdout | save -f ($out | path join $"($name).stdout")
    $ran.stderr | save -f ($out | path join $"($name).stderr")
    let kept = ($out | path join $"($name).sdl.log")
    let after = (do $state)
    if $after != null and $after != $before { cp $log $kept }
    let lines = ($ran.stdout | lines)
    let opens = ($lines | enumerate | where item == "{" | get index)
    let record = (if $ran.exit_code != 0 or ($opens | is-empty) { null } else { try { $lines | skip ($opens | last) | str join "\n" | from nuon } catch { null } })
    { exit: $ran.exit_code, record: $record, stderr: $ran.stderr, log: (if ($kept | path exists) { $kept } else { "" }) }
}

# The last lines of a run's stderr, for a failure's reason
def tail-of [text: string]: nothing -> string { $text | lines | last 4 | str join " " }

# An error's message as nushell renders it on stderr
def message-of [stderr: string]: nothing -> string {
    let lines = ($stderr | lines)
    let at = ($lines | enumerate | where {|l| $l.item =~ '^\s*x ' } | get -o 0.index)
    if $at == null { return "" }
    $lines | skip $at | take while {|l| $l =~ '^\s*(x|\|) ' } | each {|l| $l | str replace --regex '^\s*(x|\|) ' '' } | str join " "
}

# A task run with bounce's extern/qemu linked to a target, the link gone
def with-link [target: path, task: closure] {
    let extern = ($JAB | path join "example" "bounce" "extern")
    let link = ($extern | path join "qemu")
    if ($link | path type) != null { error make {msg: $"($link) is already there; the controls make that link themselves and remove it after"} }
    let made_extern = (($extern | path type) == null)
    if $made_extern { mkdir $extern }
    ^ln -s $target $link
    let attempt = (try { { value: (do $task), error: null } } catch {|e| { value: null, error: $e.msg } })
    let pointed = (^readlink $link | complete | get stdout | str trim)
    if ($link | path type) != "symlink" or $pointed != $target { error make {msg: $"($link) is no longer the link to ($target) the controls made; it is left as it is"} }
    rm $link
    if $made_extern and (ls $extern | is-empty) { rm $extern }
    if $attempt.error != null { error make {msg: $attempt.error} }
    $attempt.value
}

# Flips as the record groups them, uploads within 5 ms one flip
def flip-count [times: list<float>]: nothing -> int {
    mut flips = 0
    mut last = -1.0
    for t in $times {
        if $last < 0.0 or ($t - $last) >= 0.005 { $flips += 1 }
        $last = $t
    }
    $flips
}

# The window's make_currents of a reading, each with its place
def made-of [events: table]: nothing -> table {
    $events | where name == "make_current" | enumerate | each {|m| $m.item | insert place $m.index }
}

# How many of each kind a reading holds
def counts-of [made: table]: nothing -> record<uploads: int, switches: int, console: int, renders: int> {
    {
        uploads: ($made | where kind == "upload" | length),
        switches: ($made | where kind == "switch" | length),
        console: ($made | where kind == "console" | length),
        renders: ($made | where kind == "render" | length),
    }
}

# The monolithic control's checks over a walk's log and trace
def monolithic-of [log: path, trace: path, report: record]: nothing -> record {
    let read = (sdl classify $log)
    let made = (made-of $read.events)
    let commands = (open --raw $trace | lines
        | parse --regex '^(?P<at>\S+) (?P<command>virtio_gpu_cmd_(?:res_flush|set_scanout))\b'
        | each {|c| { ts: (($c.at | into datetime | into int) / 1e9), command: $c.command } }
        | sort-by ts)
    let windows = ($commands | enumerate | each {|c|
        let next = ($commands | get -o ($c.index + 1))
        let until = (if $next == null { 1e12 } else { $next.ts })
        let inside = ($made | where {|m| $m.ts >= $c.item.ts and $m.ts < $until })
        { command: $c.item.command, uploads: ($inside | where kind == "upload" | length), switches: ($inside | where kind == "switch" | length) }
    })
    let flushes = ($windows | where command == "virtio_gpu_cmd_res_flush")
    let scanouts = ($windows | where command == "virtio_gpu_cmd_set_scanout")
    let uploads = ($made | where kind == "upload")
    let placed = (if ($flushes | is-empty) { 0 } else { $flushes | get uploads | math sum })
    let reset = ($made | where {|m| $m.callers | str contains "virtio_gpu_reset_bh" })
    let counts = (counts-of $made)
    let checks = {
        one_upload_per_flush: (($flushes | length) > 0 and ($flushes | all {|w| $w.uploads == 1 })),
        none_elsewhere: ($placed == ($uploads | length)),
        one_switch_per_set_scanout: (($scanouts | length) > 0 and ($scanouts | all {|w| $w.switches == 1 })),
        reset_through_reset_bh: (($reset | where kind == "switch" | length) == 1 and ($reset | where kind == "console" | length) == 1),
        virtio_gpu_in_executable: ($read.virtio_gpu_in == "executable" and $report.virtio_gpu_in == "executable"),
        flips_are_groups: ($report.flips == (flip-count ($uploads | get ts))),
        switches_as_measured: ($counts.switches == $SWITCHES and $report.switches == $SWITCHES),
        console_as_measured: ($counts.console == $CONSOLE and $report.other_uploads == $CONSOLE),
    }
    {
        ok: ($checks | values | all {|v| $v }),
        traced: { flushes: ($flushes | length), set_scanouts: ($scanouts | length) },
        read: $counts,
        flush_windows: ($flushes | get uploads | uniq --count | each {|c| { uploads: $c.value, windows: $c.count } }),
        flips: $report.flips,
        checks: $checks,
    }
}

# The monolithic control: walk on the workspace's QEMU, traced
def monolithic [out: path]: nothing -> record {
    let trace = ($out | path join "walk.trace.log")
    let run = (probe-run "walk" "example/walk" $out $"($TRACE) -D \"($trace)\"")
    if $run.exit != 0 or $run.record == null or $run.log == "" { return { ran: true, ok: false, why: $"the probe failed: (tail-of $run.stderr)" } }
    if not ($trace | path exists) { return { ran: true, ok: false, why: "QEMU wrote no trace; its build may carry no log trace backend" } }
    let m = (monolithic-of $run.log $trace $run.record)
    { ran: true, ok: $m.ok, qemu: $run.record.run.qemu } | merge ($m | reject ok)
}

# The modular control's checks over a bounce's log, read twice
def modular-of [log: path, report: record]: nothing -> record {
    let read = (made-of (sdl classify $log).events)
    let named = (sdl resolve $log --every)
    let modules = ($named.objects | where {|o| $o.file | str starts-with "hw-display-virtio-gpu" } | get index)
    let gates = (made-of $named.events | each {|m|
        let caller = ($m.frames | get -o 0)
        let second = ($m.frames | get -o 1)
        let caller_names = (if $caller == null { [] } else { $caller.functions })
        let second_names = (if $second == null { [] } else { $second.functions })
        let gate = (if $m.render { "render" } else if "sdl2_gl_switch" in $caller_names { "switch" } else if "sdl2_gl_update" not-in $caller_names { "other" } else if ($second_names | any {|n| $n in $CONSOLE_UPDATES }) { "upload" } else { "console" })
        let corroborated = ($m.frames | skip 2 | any {|f| $f.object in $modules and ($f.functions | any {|n| $n | str starts-with "virtio_gpu_" }) })
        { place: $m.place, gate: $gate, corroborated: $corroborated }
    })
    let places = {|rows: table, kind: string, column: string| $rows | where {|r| ($r | get $column) == $kind } | get place }
    let flips = (do $places $read "upload" "kind")
    let counts = (counts-of $read)
    let checks = {
        virtio_gpu_in_module: ($report.virtio_gpu_in == "module" and $named.virtio_gpu_in == "module"),
        uploads_agree: ($flips == (do $places $gates "upload" "gate")),
        uploads_corroborated: (($flips | length) > 0 and ($gates | where gate == "upload" | all {|g| $g.corroborated })),
        switches_agree: ((do $places $read "switch" "kind") == (do $places $gates "switch" "gate")),
        console_agree: ((do $places $read "console" "kind") == (do $places $gates "console" "gate")),
        nothing_else: ($gates | where gate == "other" | is-empty),
        switches_as_measured: ($counts.switches == $SWITCHES and $report.switches == $SWITCHES),
        console_as_measured: ($counts.console == $CONSOLE and $report.other_uploads == $CONSOLE),
    }
    {
        ok: ($checks | values | all {|v| $v }),
        read: $counts,
        corroborated: ($gates | where gate == "upload" | where corroborated | length),
        flips: $report.flips,
        checks: $checks,
    }
}

# The modular control: bounce on a QEMU whose virtio-gpu is a module
def modular [out: path]: nothing -> record {
    let module = ($MODULE_DIRS | each {|d| $d | path join "hw-display-virtio-gpu.so" } | where {|f| $f | path exists } | get -o 0)
    if not ($SYSTEM_QEMU | path exists) or $module == null { return { ran: false, ok: false, why: "no QEMU at /usr whose virtio-gpu is a module" } }
    let run = (with-link $SYSTEM_PREFIX { probe-run "bounce" "example/bounce" $out "" })
    if $run.exit != 0 or $run.record == null or $run.log == "" { return { ran: true, ok: false, why: $"the probe failed or refused: (tail-of $run.stderr)" } }
    let m = (modular-of $run.log $run.record)
    { ran: true, ok: $m.ok, qemu: $run.record.run.qemu, module: $module } | merge ($m | reject ok)
}

# The stripped control's checks: refused at the anchor, the table named
def stripped-checks [failed: bool, printed: bool, refusal: string]: nothing -> record {
    {
        exits_nonzero: $failed,
        prints_no_record: (not $printed),
        anchor_refused: ($refusal | str contains "immediate caller is not in the SDL front end"),
        table_named: ($refusal | str contains "keeps no symbol table"),
    }
}

# The stripped control: bounce on a QEMU stripped of its symbol table
def stripped [out: path, work: path]: nothing -> record {
    let install = ($JAB | path join "extern" "qemu" | path expand)
    let binary = ($install | path join "bin" "qemu-system-riscv64")
    let tree = ($work | path join "stripped")
    mkdir ($tree | path join "bin")
    let copy = ($tree | path join "bin" "qemu-system-riscv64")
    let strip = (^strip --strip-all $binary -o $copy | complete)
    if $strip.exit_code != 0 { return { ran: true, ok: false, why: $"strip failed: ($strip.stderr | str trim)" } }
    ^ln -s ($install | path join "share") ($tree | path join "share")
    let run = (with-link $tree { probe-run "stripped" "example/bounce" $out "" })
    let refusal = (message-of $run.stderr)
    let printed = ((open --raw ($out | path join "stripped.stdout") | str trim) != "")
    let checks = (stripped-checks ($run.exit != 0) $printed $refusal)
    {
        ran: true,
        ok: ($checks | values | all {|v| $v }),
        stripped: { size: (ls -D $copy | get 0.size | into int), sha256: (open --raw $copy | into binary | hash sha256) },
        refusal: $refusal,
        checks: $checks,
    }
}

# The controls run, one NUON record kept under `out` and printed
export def main [out: path, work: path] {
    let out = ($out | path expand)
    let work = ($work | path expand)
    if ($out | path type) != null { error make {msg: $"($out) is already there; a run's record is written once"} }
    mkdir $out
    mkdir $work
    let mono = (monolithic $out)
    let modu = (modular $out)
    let strip = (stripped $out $work)
    let record = {
        jab: (^git -C $JAB rev-parse HEAD | str trim),
        workbench: (^git -C $HERE rev-parse HEAD | str trim),
        seconds: $SECONDS,
        monolithic: $mono,
        modular: $modu,
        stripped: $strip,
        ok: ($mono.ok and $strip.ok and ($modu.ok or not $modu.ran)),
    }
    $record | to nuon --indent 2 | save -f ($out | path join "controls.nuon")
    print ($record | to nuon --indent 2)
    if not $record.ok { exit 1 }
}

# The fields a reread holds to its record that differ, both values
def discrepancies [reread: record, recorded: record, fields: list<string>]: nothing -> list<string> {
    $fields | where {|f| ($reread | get $f) != ($recorded | get -o $f) } | each {|f|
        $"($f): recorded ($recorded | get -o $f | to nuon), reread ($reread | get $f | to nuon)"
    }
}

# One control reread by the current reader over its saved files
def reread-one [recorded: record, fields: list<string>, task: closure]: nothing -> record {
    let got = (try { { value: (do $task), error: null } } catch {|e| { value: null, error: $e.msg } })
    if $got.error != null { return { reread: true, ok: false, discrepancies: [$"the reader raised: ($got.error)"] } }
    { reread: true } | merge $got.value | merge { discrepancies: (discrepancies $got.value $recorded $fields) }
}

# The executable the stripped control's log names, or why it names none
def stripped-target [log: path]: nothing -> record<problem: string, path: string, gone: bool> {
    if ($log | path type) == null { return { problem: "the record holds no stripped.sdl.log", path: "", gone: false } }
    let read = (try { { objects: (sdl log $log).objects, error: null } } catch {|e| { objects: [], error: $e.msg } })
    if $read.error != null { return { problem: $"the reader refuses the stripped log: ($read.error)", path: "", gone: false } }
    let entry = ($read.objects | where index == 0 | get -o 0)
    let which = (if $entry == null {
        "its table has no object 0"
    } else if $entry.inode == null or $entry.size == null or $entry.mtime == null {
        "object 0 is written - - -"
    } else if $entry.path == "" {
        "object 0 names no path"
    } else if not ($entry.path | str starts-with "/") {
        $"object 0's path is not absolute: ($entry.path)"
    } else { "" })
    if $which != "" { return { problem: $"the stripped log names no executable: ($which)", path: "", gone: false } }
    if ($entry.path | str ends-with " (deleted)") { return { problem: $"the stripped log names an executable deleted at its capture: ($entry.path)", path: $entry.path, gone: false } }
    { problem: "", path: $entry.path, gone: (($entry.path | path type) == null) }
}

# A controls run's record reread by the current reader, nothing run
export def reread [record: path] {
    let dir = ($record | path expand)
    let saved = (open --raw ($dir | path join "controls.nuon") | into binary | decode | from nuon)
    let unran = { reread: false, why: "the control did not run" }
    let mono = (if not $saved.monolithic.ran { $unran } else {
        reread-one $saved.monolithic [ok traced read flush_windows flips checks] {||
            let log = ($dir | path join "walk.sdl.log")
            monolithic-of $log ($dir | path join "walk.trace.log") (sdl report $log)
        }
    })
    let modu = (if not $saved.modular.ran { $unran } else {
        reread-one $saved.modular [ok read corroborated flips checks] {||
            let log = ($dir | path join "bounce.sdl.log")
            modular-of $log (sdl report $log)
        }
    })
    let stripped_log = ($dir | path join "stripped.sdl.log")
    let strip = (if not $saved.stripped.ran { $unran } else {
        let target = (stripped-target $stripped_log)
        if $target.problem != "" {
            { reread: true, ok: false, discrepancies: [$target.problem] }
        } else if $target.gone {
            { reread: false, why: $"the stripped copy its log names is gone: ($target.path)" }
        } else {
            reread-one $saved.stripped [ok checks] {||
                let reading = (try { { report: (sdl report $stripped_log), refusal: "" } } catch {|e| { report: null, refusal: $e.msg } })
                let checks = (stripped-checks ($reading.report == null) ($reading.report != null) $reading.refusal)
                { ok: ($checks | values | all {|v| $v }), refusal: $reading.refusal, checks: $checks }
            }
        }
    })
    let reread = ([$mono $modu $strip] | where {|c| $c.reread })
    let result = {
        record: $dir,
        captured: { jab: $saved.jab, workbench: $saved.workbench },
        reread_by: { jab: (^git -C $JAB rev-parse HEAD | str trim), workbench: (^git -C $HERE rev-parse HEAD | str trim) },
        monolithic: $mono,
        modular: $modu,
        stripped: $strip,
        ok: (($reread | is-not-empty) and ($reread | all {|c| $c.discrepancies | is-empty })),
    }
    print ($result | to nuon --indent 2)
    if not $result.ok { exit 1 }
}
