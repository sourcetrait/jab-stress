use (path self ../../../../../../jab/nu/mod/spec)
use (path self ../matrix)
use (path self ../matrix) [CASES JAB TARGETS]

# The fields a value lacks of those named, each named where it sits
def lacking [value: any, keys: list<string>, at: string]: nothing -> list<string> {
    if not (($value | describe) | str starts-with "record") { return [$"($at) is no record"] }
    $keys | where {|k| $k not-in ($value | columns) } | each {|k| $"($at) holds no ($k)" }
}

# A record's schema: every field it lacks, named
def schema-problems [r: any]: nothing -> list<string> {
    let top = (lacking $r [target written readers candidate spec bench hosts ram runs cases diagnostics limits] "the record")
    if not ($top | is-empty) { return $top }
    let cand = (lacking $r.candidate [tag jab stress image_sha256 elf_sha256 kernel_sha256 assets] "the candidate")
    let runs = ($r.runs | enumerate | each {|e| lacking $e.item [step run seed kind standing reasons identity agreement measured] $"run ($e.index)" } | flatten)
    let verdicts = ($r.runs | where {|x| ($x | describe | str starts-with "record") and ($x | get -o step) != null and ($CASES | where kind == acceptance | any {|c| $x.step in ($c.steps | get -o $r.target | default []) }) } | each {|x|
        if ($x | get -o verdict) == null { [$"($x.step) run ($x.run) holds no verdict"] } else { lacking $x.verdict [pass median_us under over frames problems] $"($x.step) run ($x.run)'s verdict" }
    } | flatten)
    let cases = ($r.cases | enumerate | each {|e| lacking $e.item [case kind steps runs expected missing problems reading] $"case ($e.index)" } | flatten)
    let named = ($CASES | where {|c| $c.case not-in ($r.cases | get -o case | default []) } | each {|c| $"the record holds no case ($c.case)" })
    $cand ++ $runs ++ $verdicts ++ $cases ++ $named
}

# A record held to the schema and the acceptance, every problem named
export def check-of [r: any]: nothing -> list<string> {
    let schema = (schema-problems $r)
    if not ($schema | is-empty) { return $schema }
    let cand = $r.candidate
    let spec = (try { spec row $JAB $r.target } catch { null })
    if $r.target not-in $TARGETS or $spec == null { return [$"the record's target, ($r.target), is no target of the qualification's matrix"] }
    let tag = (if $cand.tag == null { ["the candidate is untagged, so no qualification stands on it"] } else { [] })
    let bench = ($r.bench.problems | each {|p| $"the bench: ($p)" })
    let acceptance = ($r.cases | where kind == acceptance | each {|c|
        let missing = ($c.missing | each {|m| $"($c.case): ($m.step) run ($m.run), seed ($m.seed), is missing" })
        let reseeded = ($c.problems | each {|p| $"($c.case): ($p)" })
        let judged = ($c.runs | each {|ref|
            let run = ($r.runs | where {|x| $x.step == $ref.step and $x.run == $ref.run } | get 0)
            let agreement = (matrix agreement-of $run.identity $cand $r.target $spec)
            let again = (matrix verdict-of ($run | update agreement $agreement))
            let name = $"($c.case): (matrix run-name $run), seed ($run.seed)"
            let drift = (if $agreement != $run.agreement or $again.pass != $run.verdict.pass or $again.problems != $run.verdict.problems {
                [$"($name): the record's verdict, (if $run.verdict.pass { 'pass' } else { 'fail' }), is not the one its own fields give, (if $again.pass { 'pass' } else { 'fail' })"]
            } else { [] })
            $drift ++ ($again.problems | each {|p| $"($name): ($p)" })
        } | flatten)
        $missing ++ $reseeded ++ $judged
    } | flatten)
    let controls = ($r.cases | where kind == control | each {|c|
        let reseeded = ($c.problems | each {|p| $"($c.case): ($p)" })
        let unmet = (if $c.reading.met { [] } else { $c.reading.problems | each {|p| $"($c.case): ($p)" } })
        $reseeded ++ $unmet
    } | flatten)
    let presented = ($r.cases | where kind == diagnostic | each {|c|
        let reseeded = ($c.problems | each {|p| $"($c.case): ($p)" })
        let unread = (if $c.reading.read { [] } else { $c.reading.problems | each {|p| $"($c.case): ($p)" } })
        $reseeded ++ $unread
    } | flatten)
    let diagnostics = ($r.diagnostics | each {|d|
        let unread = (if ($d.readings | is-empty) { [$"($d.case): no normal play route run to read"] } else { [] })
        $unread ++ ($d.missing | each {|m| $"($d.case): ($m)" })
    } | flatten)
    $tag ++ $bench ++ $acceptance ++ $controls ++ $presented ++ $diagnostics
}

# A record held to the schema and the acceptance, every problem printed
export def main [record: path] {
    let problems = (check-of (open $record))
    for p in $problems { print $"qualification: ($p)" }
    if not ($problems | is-empty) { error make { msg: $"($record): ($problems | length) problems" } }
    print $"qualification: ($record) holds"
}
