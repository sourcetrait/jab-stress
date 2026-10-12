# The cases as the checkout runner (runners/checkout_mutants.nuon) reads
# them: a scratch checkout at <dir>, a git repository of its own whose one
# commit holds `case`, its whole text `control`; a justfile whose `test
# cases` prints the canned log `case` names, from this directory's logs/,
# and exits 1 when it holds nushell's error, else 0; `set.nuon`,
# cases.nuon's cases as a mutant set of the one program `cases`, each one
# edit making `case` its own name, with its `expect` and `class`; and for
# each forced case `set_<case>.nuon`, the same set with that case last.
# Every case's run so exercises the runner's finds and its restore.
#
# The forced cases are the runner's deadline and recovery proofs, kept
# out of cases.nuon so no other consumer of the cases reads them:
# - overrun_sleep sleeps a minute, which TERM ends;
# - overrun_ignore runs a sleep that ignores TERM;
# - overrun_nested leaves a nested `timeout` of 120 s, in a group of its
#   own, over a long sleep, then sleeps a minute;
# - orphan starts a long sleep in a session of its own, then sleeps a
#   minute.
#
# Usage: nu checkout.nu <dir>
#
# <dir> must not exist. The runner then takes `jab` <dir>, `set`
# <dir>/set.nuon or a forced case's set, `only` its names, and `control`
# {program: cases, ok: "eviction reuse: ok"}, the canned control log its
# passing run.
def main [dir: path] {
    if ($dir | path type) != null { error make {msg: $"($dir) exists; a scratch checkout starts empty"} }
    let logs = ($env.FILE_PWD | path join "logs")
    if ($logs | str contains "'") { error make {msg: $"($logs) holds a quote the justfile cannot carry"} }
    let recipe = r#'    let name = (open --raw ('{{justfile_directory()}}' | path join case) | decode); if '{{program}}' != 'cases' { print -e 'cases is the one program here'; exit 2 }; if $name == 'overrun_sleep' { sleep 60sec; exit 0 }; if $name == 'overrun_ignore' { ^sh -c 'trap "" TERM; exec sleep 60'; exit 0 }; if $name == 'overrun_nested' { ^sh -c 'timeout 120 sleep 300 & exec sleep 60'; exit 0 }; if $name == 'orphan' { ^setsid -f sleep 300; sleep 60sec; exit 0 }; let log = (open --raw ('{{logs}}' | path join $"($name).log") | decode); print -n $log; exit (if ($log | str contains "Error: ") { 1 } else { 0 })'#
    let justfile = [
        "# The checkout runner's scratch checkout, written by checkout.nu: `test"
        "# cases` prints the canned log the file `case` names and exits 1 when it"
        "# holds nushell's error, else 0; a forced case does what it forces."
        ""
        'set shell := ["nu", "-c"]'
        "set quiet := true"
        ""
        $"logs := '($logs)'"
        ""
        "test program:"
        $recipe
        ""
    ]
    let case_of = {|name: string, expect: string, class: string|
        { name: $name, program: "cases", expect: $expect, class: $class, edits: [{ file: "case", find: "control", put: $name }] }
    }
    let set = (open ($env.FILE_PWD | path join "cases.nuon") | each {|c| do $case_of $c.name $c.expect $c.class })
    let forced = ["overrun_sleep" "overrun_ignore" "overrun_nested" "orphan"]
    mkdir $dir
    "control" | save --raw ($dir | path join "case")
    $justfile | str join (char nl) | save --raw ($dir | path join "justfile")
    $set | to nuon --indent 2 | save --raw ($dir | path join "set.nuon")
    for f in $forced {
        $set | append (do $case_of $f "" "overrun") | to nuon --indent 2 | save --raw ($dir | path join $"set_($f).nuon")
    }
    ^git -C $dir init -q -b main
    ^git -C $dir add -A
    ^git -C $dir -c commit.gpgsign=false commit -q -m "the checkout runner's scratch checkout"
    print $"checkout: ($dir), a git repository, ($set | length) cases in its set.nuon and ($forced | length) forced sets"
}
