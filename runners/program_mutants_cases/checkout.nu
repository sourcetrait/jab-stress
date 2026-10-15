# The cases as the checkout runner (runners/checkout_mutants.nuon) reads
# them: a scratch checkout at <dir>, a git repository of its own whose one
# commit holds `case`, its whole text `control`; a justfile whose `test
# cases` prints the canned log `case` names, from the data checkout's
# assets/workbench/cases/logs/, and exits 1 when it holds nushell's error,
# else 0; `set.nuon`, cases.nuon's cases as a mutant set of the one program
# `cases`, each one edit making `case` its own name, with its `expect` and
# `class`; and for each forced case `set_<case>.nuon`, the same set with
# that case last. Every case's run so exercises the runner's finds and its
# restore.
#
# The forced cases are the runner's deadline, sweep, and recovery proofs,
# kept out of cases.nuon so no other consumer of the cases reads them:
# - overrun_sleep sleeps a minute, which TERM ends;
# - overrun_ignore runs a sleep that ignores TERM;
# - overrun_nested leaves a nested `timeout` of 120 s, in a group of its
#   own, over a long sleep, then sleeps a minute;
# - orphan starts a long sleep in a session of its own, then sleeps a
#   minute;
# - cleanup_child starts, in a session of its own, a shell whose TERM trap
#   starts a long sleep in a session of its own and exits, the shell's own
#   sleep under a `wait` the trap interrupts; it waits for the trap to be
#   set, then reads as catch_assert, so the sweep's TERM begets a child;
# - survivor writes an entry carrying the run's mark into the stand-in
#   beside the checkout (standin.nu), a process no signal ends, then reads
#   as catch_assert.
#
# Usage: nu checkout.nu <dir>
#
# <dir> must not exist, and the data checkout beside this repository,
# ../jab-stress-data, must hold the canned logs. The runner then takes
# `jab` <dir>, `set` <dir>/set.nuon or a forced case's set, `only` its
# names, and `control` {program: cases, ok: "eviction reuse: ok"}, the
# canned control log its passing run; for set_survivor.nuon its `proc` is
# `<dir>.proc`, which standin.nu lays out.

use ../guard.nu [MARK]
use ./standin.nu [STANDIN_PID]

def main [dir: path] {
    if ($dir | path type) != null { error make {msg: $"($dir) exists; a scratch checkout starts empty"} }
    if ($dir | path expand | str contains "'") { error make {msg: $"($dir) holds a quote the justfile cannot carry"} }
    let logs = ($env.FILE_PWD | path join ".." ".." ".." "jab-stress-data" "assets" "workbench" "cases" "logs" | path expand)
    if ($logs | path type) != "dir" { error make {msg: $"no canned logs at ($logs); the data checkout beside this repository holds them"} }
    if ($logs | str contains "'") { error make {msg: $"($logs) holds a quote the justfile cannot carry"} }
    let recipe = r#'    let name = (open --raw ('{{justfile_directory()}}' | path join case) | decode); if '{{program}}' != 'cases' { print -e 'cases is the one program here'; exit 2 }; if $name == 'overrun_sleep' { sleep 60sec; exit 0 }; if $name == 'overrun_ignore' { ^sh -c 'trap "" TERM; exec sleep 60'; exit 0 }; if $name == 'overrun_nested' { ^sh -c 'timeout 120 sleep 300 & exec sleep 60'; exit 0 }; if $name == 'orphan' { ^setsid -f sleep 300; sleep 60sec; exit 0 }; if $name == 'cleanup_child' { let ready = ('{{justfile_directory()}}' | path join '.git' 'cleanup_child.ready'); ^setsid -f sh -c $"trap 'setsid -f sleep 300; exit 0' TERM; : > '($ready)'; sleep 300 & wait"; mut waited = 0; while (not ($ready | path exists)) and $waited < 50 { sleep 100ms; $waited += 1 }; if not ($ready | path exists) { print -e 'cleanup_child: its shell never set its trap'; exit 2 } }; if $name == 'survivor' { let standin = $"('{{justfile_directory()}}').proc"; if ($standin | path type) != 'dir' { print -e $"survivor: no stand-in at ($standin)"; exit 2 }; let entry = ($standin | path join '{{standin_pid}}'); let nul = (char --unicode '0'); mkdir $entry; $"{{mark}}=($env | get '{{mark}}')($nul)" | save --raw ($entry | path join 'environ'); '{{standin_pid}} (sleep) S 1 {{standin_pid}} {{standin_pid}} 0 -1 0' | save --raw ($entry | path join 'stat'); $"sleep($nul)300($nul)" | save --raw ($entry | path join 'cmdline') }; let canned = (if $name in ['cleanup_child' 'survivor'] { 'catch_assert' } else { $name }); let log = (open --raw ('{{logs}}' | path join $"($canned).log") | decode); print -n $log; exit (if ($log | str contains "Error: ") { 1 } else { 0 })'#
    let justfile = [
        "# The checkout runner's scratch checkout, written by checkout.nu: `test"
        "# cases` prints the canned log the file `case` names and exits 1 when it"
        "# holds nushell's error, else 0; a forced case does what it forces."
        ""
        'set shell := ["nu", "-c"]'
        "set quiet := true"
        ""
        $"logs := '($logs)'"
        $"mark := '($MARK)'"
        $"standin_pid := '($STANDIN_PID)'"
        ""
        "test program:"
        $recipe
        ""
    ]
    let case_of = {|name: string, expect: string, class: string|
        { name: $name, program: "cases", expect: $expect, class: $class, edits: [{ file: "case", find: "control", put: $name }] }
    }
    let cases = (open ($env.FILE_PWD | path join "cases.nuon"))
    let set = ($cases | each {|c| do $case_of $c.name $c.expect $c.class })
    let catch = ($cases | where name == "catch_assert" | first)
    let forced = [
        [name, expect, class];
        ["overrun_sleep", "", "overrun"]
        ["overrun_ignore", "", "overrun"]
        ["overrun_nested", "", "overrun"]
        ["orphan", "", "overrun"]
        ["cleanup_child", $catch.expect, "caught"]
        ["survivor", $catch.expect, "caught"]
    ]
    mkdir $dir
    "control" | save --raw ($dir | path join "case")
    $justfile | str join (char nl) | save --raw ($dir | path join "justfile")
    $set | to nuon --indent 2 | save --raw ($dir | path join "set.nuon")
    for f in $forced {
        let forced_set = ($set | append (do $case_of $f.name $f.expect $f.class))
        $forced_set | to nuon --indent 2 | save --raw ($dir | path join $"set_($f.name).nuon")
    }
    ^git -C $dir init -q -b main
    ^git -C $dir add -A
    ^git -C $dir -c commit.gpgsign=false commit -q -m "the checkout runner's scratch checkout"
    print $"checkout: ($dir), a git repository, ($set | length) cases in its set.nuon and ($forced | length) forced sets"
}
