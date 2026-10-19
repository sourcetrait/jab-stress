#!/usr/bin/env nu
# The qualification module's path, bound at parse time
const QUALIFICATION = path self ../../../mod/fierce/qualification
use $QUALIFICATION

# The candidate's record at its freeze, written to `out`
def "main candidate" [out: path, --tag: string = ""] {
    qualification candidate $out --tag $tag
}

# A target's record written to `out`, its check's problems printed
def "main record" [bench: path, candidate: path, target: string, out: path] {
    qualification record $bench $candidate $target $out
}

# A record held to the schema and the acceptance, every problem printed
def "main check" [record: path] {
    qualification check $record
}

# The report over records, the last path its Markdown file
def "main report" [...paths: path, --compared: string = ""] {
    qualification report ...$paths --compared $compared
}

def main [] { help main }
