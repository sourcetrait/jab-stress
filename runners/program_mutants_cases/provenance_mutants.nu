# The provenance rule's own mutants, each a `name`, `find`, `put`, and
# `expect`, the case it must misread, run on mirrors so the rule in this
# repository is never touched. A control mirror holds the rule as it
# stands; each mutant's mirror holds it with the mutant's find, which must
# match exactly once, replaced by its put. Each mirror is read over every
# case in cases.nuon by provenance_read.nu copied beside it, and a case is
# misread when its `at_assert` differs from the case's own. The control
# must misread none; a mutant is caught when its mirror misreads its
# `expect` case. Prints the summary as NUON and exits 1 unless the control
# holds and every mutant is applied and caught.
#
# Usage: nu provenance_mutants.nu <set> <scratch> [--data <checkout>]
#
# <set> is the mutant set, assets/workbench/mutants/provenance_mutants.nuon
# in the data checkout, and <scratch> a directory that must not exist,
# where the mirrors are laid out. The canned logs are the data checkout's
# assets/workbench/cases/logs/: ../jab-stress-data beside this repository,
# or the checkout --data names.
def main [set: path, scratch: path, --data: path] {
    let here = $env.FILE_PWD
    let checkout = (if $data == null { $here | path join ".." ".." ".." "jab-stress-data" } else { $data } | path expand)
    let logs = ($checkout | path join "assets" "workbench" "cases" "logs")
    if ($logs | path type) != "dir" {
        error make {msg: $"no canned logs at ($logs)"}
    }
    if ($scratch | path exists) {
        error make {msg: $"($scratch) exists; the mirrors are laid out in a new directory"}
    }
    let cases = ($here | path join "cases.nuon")
    let expected = (open $cases | select name at_assert)
    let rule = (open --raw ($here | path join ".." "provenance.nu") | decode)
    let reader = ($here | path join "provenance_read.nu")
    mkdir $scratch
    let read = {|name: string, text: string|
        let dir = ($scratch | path join $name)
        mkdir $dir
        $text | save --raw ($dir | path join "provenance.nu")
        cp $reader $dir
        let r = (^nu ($dir | path join "provenance_read.nu") $cases $logs | complete)
        if $r.exit_code != 0 {
            return {ok: false, error: ($r.stderr | str trim | str substring 0..400), misread: []}
        }
        let got = ($r.stdout | from nuon)
        let misread = ($expected | where {|e| ($got | where name == $e.name | get -o 0.at_assert) != $e.at_assert } | get name)
        {ok: true, error: "", misread: $misread}
    }
    let control = (do $read "control" $rule)
    mut results = []
    for m in (open $set) {
        let count = (($rule | split row $m.find | length) - 1)
        if $count != 1 {
            $results = ($results | append {name: $m.name, applied: false, count: $count, caught: false, misread: [], error: ""})
        } else {
            let r = (do $read $m.name ($rule | str replace $m.find $m.put))
            $results = ($results | append {name: $m.name, applied: true, count: 1, caught: ($r.ok and ($m.expect in $r.misread)), misread: $r.misread, error: $r.error})
        }
    }
    let summary = {
        control_ok: ($control.ok and ($control.misread | is-empty)),
        control_misread: $control.misread,
        control_error: $control.error,
        every: ($results | all {|x| $x.applied and $x.caught }),
        results: $results,
    }
    print ($summary | to nuon)
    if not ($summary.control_ok and $summary.every) { exit 1 }
}
