# The sdl probe's controls: `just do probe sdl` run three ways in the Jab
# checkout beside this one, each held to an oracle the probe does not
# make, and one NUON record printed. Every file of the run is written
# under `out`, a directory not yet there, which is the run's record; the
# stripped QEMU goes under `work`.
#
# - monolithic: walk for 12 s on the workspace's QEMU, with QEMU's own
#   trace of the device's flush and set_scanout commands written through
#   JAB_QEMU_ARGS, which takes a QEMU carrying the log trace backend. After
#   every traced flush exactly one flip's upload comes before the next
#   traced command, and none comes anywhere else; after every traced
#   set_scanout exactly one switch; the reset's switch and redraw come
#   through virtio_gpu_reset_bh; the device's code reads in the
#   executable; and the record's flips are the 5 ms groups of those
#   uploads.
# - modular: bounce for 12 s on the system's QEMU where its virtio-gpu is
#   a module, through example/bounce/extern/qemu linked to /usr for the
#   run alone: the device's code reads in a module and nothing is refused.
#   The log is then read a second time by symbols alone, through the same
#   gates, the immediate caller and the frame after it, every frame named
#   wherever its object's table answers: every flip's upload is
#   corroborated by a later frame in an exported virtio_gpu_* function of
#   the module, and the flips, switches, and the console's own are the
#   same make_currents in both readings. With no such QEMU installed the
#   control is marked not run.
# - stripped: the workspace's QEMU stripped of its symbol table into
#   `work`, its share linked to the install's, run on bounce through the
#   same link: the probe exits non-zero with the anchor's refusal naming
#   the missing table, and prints no record.
#
# On each QEMU the window's own make_currents are expected as measured:
# three switches, the registration's, the reset's, and the set_scanout's,
# and two of the console's own, the registration's first update and the
# reset's redraw.
use ../../../../jab/sdk/nu/jab.nu

const HERE = (path self | path dirname)
const JAB = (path self | path dirname | path join .. .. .. .. jab | path expand)
const SECONDS = 12
const SWITCHES = 3
const CONSOLE = 2
const TRACE = "-msg timestamp=on -trace virtio_gpu_cmd_res_flush -trace virtio_gpu_cmd_set_scanout"
const SYSTEM_QEMU = "/usr/bin/qemu-system-riscv64"
const SYSTEM_PREFIX = "/usr"
const MODULE_DIRS = ["/usr/lib64/qemu" "/usr/lib/qemu" "/usr/lib/x86_64-linux-gnu/qemu"]
const CONSOLE_UPDATES = ["qemu_console_update" "qemu_console_update_full" "dpy_gfx_update" "dpy_gfx_update_full"]

# One probe run, `just do probe sdl <program>` for SECONDS with
# `qemu_args` in JAB_QEMU_ARGS: its exit, its record where it printed one,
# its stderr, and its shim log, each kept under `out` by `name`.
def probe-run [name: string, program: string, out: path, qemu_args: string]: nothing -> record<exit: int, record: oneof<record, nothing>, stderr: string, log: string> {
    let tool = ($JAB | path join "sdk" "nu" "jab.nu")
    let ran = (with-env { JAB_QEMU_ARGS: $qemu_args } { ^$nu.current-exe $tool probe $JAB sdl $program --seconds ($SECONDS | into string) | complete })
    $ran.stdout | save -f ($out | path join $"($name).stdout")
    $ran.stderr | save -f ($out | path join $"($name).stderr")
    let log = (jab program-out ($JAB | path join $program) "release" | path join "probe" "sdl.log")
    let kept = ($out | path join $"($name).sdl.log")
    if ($log | path exists) { cp $log $kept }
    let lines = ($ran.stdout | lines)
    let opens = ($lines | enumerate | where item == "{" | get index)
    let record = (if $ran.exit_code != 0 or ($opens | is-empty) { null } else { try { $lines | skip ($opens | last) | str join "\n" | from nuon } catch { null } })
    { exit: $ran.exit_code, record: $record, stderr: $ran.stderr, log: (if ($kept | path exists) { $kept } else { "" }) }
}

# The last lines of a run's stderr, for a failure's reason.
def tail-of [text: string]: nothing -> string { $text | lines | last 4 | str join " " }

# An error's message as nushell renders it on stderr, its title read
# through the continuation lines it wraps onto.
def message-of [stderr: string]: nothing -> string {
    let lines = ($stderr | lines)
    let at = ($lines | enumerate | where {|l| $l.item =~ '^\s*x ' } | get -o 0.index)
    if $at == null { return "" }
    $lines | skip $at | take while {|l| $l =~ '^\s*(x|\|) ' } | each {|l| $l | str replace --regex '^\s*(x|\|) ' '' } | str join " "
}

# Runs `task` with example/bounce/extern/qemu linked to `target` for the
# run alone, refusing a path already taken, and removes the link after,
# checked to be the one made, and extern/ with it where the run made that.
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

# Flips as the record groups them: each upload within 5 ms of the one
# before joins its flip.
def flip-count [times: list<float>]: nothing -> int {
    mut flips = 0
    mut last = -1.0
    for t in $times {
        if $last < 0.0 or ($t - $last) >= 0.005 { $flips += 1 }
        $last = $t
    }
    $flips
}

# The window's make_currents of a reading, each with its place among them.
def made-of [events: table]: nothing -> table {
    $events | where name == "make_current" | enumerate | each {|m| $m.item | insert place $m.index }
}

# How many of each kind a reading holds.
def counts-of [made: table]: nothing -> record<uploads: int, switches: int, console: int, renders: int> {
    {
        uploads: ($made | where kind == "upload" | length),
        switches: ($made | where kind == "switch" | length),
        console: ($made | where kind == "console" | length),
        renders: ($made | where kind == "render" | length),
    }
}

def monolithic [out: path]: nothing -> record {
    let trace = ($out | path join "walk.trace.log")
    let run = (probe-run "walk" "example/walk" $out $"($TRACE) -D \"($trace)\"")
    if $run.exit != 0 or $run.record == null or $run.log == "" { return { ran: true, ok: false, why: $"the probe failed: (tail-of $run.stderr)" } }
    if not ($trace | path exists) { return { ran: true, ok: false, why: "QEMU wrote no trace; its build may carry no log trace backend" } }
    let read = (jab sdl-classify $run.log)
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
        virtio_gpu_in_executable: ($read.virtio_gpu_in == "executable" and $run.record.virtio_gpu_in == "executable"),
        flips_are_groups: ($run.record.flips == (flip-count ($uploads | get ts))),
        switches_as_measured: ($counts.switches == $SWITCHES and $run.record.switches == $SWITCHES),
        console_as_measured: ($counts.console == $CONSOLE and $run.record.other_uploads == $CONSOLE),
    }
    {
        ran: true,
        ok: ($checks | values | all {|v| $v }),
        qemu: $run.record.run.qemu,
        traced: { flushes: ($flushes | length), set_scanouts: ($scanouts | length) },
        read: $counts,
        flush_windows: ($flushes | get uploads | uniq --count | each {|c| { uploads: $c.value, windows: $c.count } }),
        flips: $run.record.flips,
        checks: $checks,
    }
}

def modular [out: path]: nothing -> record {
    let module = ($MODULE_DIRS | each {|d| $d | path join "hw-display-virtio-gpu.so" } | where {|f| $f | path exists } | get -o 0)
    if not ($SYSTEM_QEMU | path exists) or $module == null { return { ran: false, ok: false, why: "no QEMU at /usr whose virtio-gpu is a module" } }
    let run = (with-link $SYSTEM_PREFIX { probe-run "bounce" "example/bounce" $out "" })
    if $run.exit != 0 or $run.record == null or $run.log == "" { return { ran: true, ok: false, why: $"the probe failed or refused: (tail-of $run.stderr)" } }
    let read = (made-of (jab sdl-classify $run.log).events)
    let named = (jab sdl-resolve $run.log --every)
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
        virtio_gpu_in_module: ($run.record.virtio_gpu_in == "module" and $named.virtio_gpu_in == "module"),
        uploads_agree: ($flips == (do $places $gates "upload" "gate")),
        uploads_corroborated: (($flips | length) > 0 and ($gates | where gate == "upload" | all {|g| $g.corroborated })),
        switches_agree: ((do $places $read "switch" "kind") == (do $places $gates "switch" "gate")),
        console_agree: ((do $places $read "console" "kind") == (do $places $gates "console" "gate")),
        nothing_else: ($gates | where gate == "other" | is-empty),
        switches_as_measured: ($counts.switches == $SWITCHES and $run.record.switches == $SWITCHES),
        console_as_measured: ($counts.console == $CONSOLE and $run.record.other_uploads == $CONSOLE),
    }
    {
        ran: true,
        ok: ($checks | values | all {|v| $v }),
        qemu: $run.record.run.qemu,
        module: $module,
        read: $counts,
        corroborated: ($gates | where gate == "upload" | where corroborated | length),
        flips: $run.record.flips,
        checks: $checks,
    }
}

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
    let checks = {
        exits_nonzero: ($run.exit != 0),
        prints_no_record: ((open --raw ($out | path join "stripped.stdout") | str trim) == ""),
        anchor_refused: ($refusal | str contains "immediate caller is not in the SDL front end"),
        table_named: ($refusal | str contains "keeps no symbol table"),
    }
    {
        ran: true,
        ok: ($checks | values | all {|v| $v }),
        stripped: { size: (ls -D $copy | get 0.size | into int), sha256: (open --raw $copy | into binary | hash sha256) },
        refusal: $refusal,
        checks: $checks,
    }
}

# The controls, one NUON record: each control's checks and what it read,
# and `ok` where every control that ran passed.
def main [out: path, work: path] {
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
