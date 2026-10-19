#!/usr/bin/env nu
# The qualification module's path, bound at parse time
const QUALIFICATION = path self ../../../mod/fierce/qualification
use $QUALIFICATION

# The candidate's record at its freeze, written to `out`
def "main candidate" [out: path, --tag: string = ""] {
    qualification candidate $out --tag $tag
}

# A target's record written to `out`, its own verdicts printed
def "main record" [bench: path, candidate: path, target: string, out: path] {
    qualification record $bench $candidate $target $out
}

# A record derived again from its bench's reopened inputs, its ledger checked
def "main check" [record: path, --bench: string = "", --inventory: string = "", --candidate: string = "", --out: string = ""] {
    qualification check $record --bench $bench --inventory $inventory --candidate $candidate --out $out
}

# The report over checks, the last path its Markdown file
def "main report" [...paths: path, --compared: string = ""] {
    qualification report ...$paths --compared $compared
}

# The candidate's host package for a target, one tar from its export
def "main package" [candidate: path, export: path, target: string, out: path, --stage: string = ""] {
    qualification package $candidate $export $target $out --stage $stage
}

def main [] { help main }
