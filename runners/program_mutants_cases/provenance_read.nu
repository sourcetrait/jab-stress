# One mirror's reading of the cases: each case's canned log read through
# the provenance.nu beside this file, the rule's `at_assert` for it.
#
# Usage: nu provenance_read.nu <cases.nuon> <logs>
#
# provenance_mutants.nu copies this file into each mirror it lays out, so
# the `use` below reads that mirror's rule.
use ./provenance.nu [failure-of assertion-kind]

def main [cases: path, logs: path] {
    let read = (open $cases | each {|c|
        let ls = (open --raw ($logs | path join $"($c.name).log") | decode | lines)
        let failure = (failure-of $ls)
        {name: $c.name, at_assert: ((assertion-kind $ls $failure) != null)}
    })
    print ($read | to nuon)
}
