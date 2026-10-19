use (path self ../../../../../../jab/nu/mod/spec)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../matrix)
use (path self ../record)
use (path self ../matrix) [CASES JAB RECORD TARGETS]

# The check's own file beside the record it derives again
const CHECK = "check.nuon"

# The files a kept run's reading reopens
const RUN_FILES = ["api.out" "identity.nuon" "route.nuon" "run.nuon"]

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
    let cases = ($r.cases | enumerate | each {|e| lacking $e.item [case kind steps runs expected missing problems reading] $"case ($e.index)" } | flatten)
    let named = ($CASES | where {|c| $c.case not-in ($r.cases | get -o case | default []) } | each {|c| $"the record holds no case ($c.case)" })
    $cand ++ $runs ++ $cases ++ $named
}

# Every kept file the check reads held to its inventory row by SHA-256
def reopened [bench: path, inventory: string]: nothing -> record<checked: int, problems: list<string>> {
    if $inventory == "" { return { checked: 0, problems: [] } }
    let rows = (open $inventory)
    let manifest = ($bench | path join "preflight" "package.nuon")
    let read = (glob ($bench | path join "*" "run_*" "*") | where {|f| ($f | path basename) in $RUN_FILES } | append ($bench | path join "bench.nuon") | append (if ($manifest | path exists) { [$manifest] } else { [] }))
    let problems = ($read | each {|f|
        let rel = ($f | path relative-to $bench)
        let row = ($rows | where path == $rel | get -o 0)
        let sha = (open --raw $f | hash sha256)
        if $row == null { $"($rel) is no original of the inventory" } else if $row.sha256 != $sha { $"($rel) has SHA-256 ($sha) where the inventory names ($row.sha256)" }
    } | compact)
    let absent = ($rows | where {|x| $x.disposition in [kept archived] and (($x.path | path basename) in $RUN_FILES or $x.path == "bench.nuon") and not ($bench | path join $x.path | path exists) } | each {|x| $"($x.path) is kept by the inventory and absent from the bench" })
    { checked: ($read | length), problems: ($problems ++ $absent) }
}

# The bench laid out again in `work`: its listing beside every step's report made again
def rebuilt [bench: path, work: path]: nothing -> nothing {
    mkdir $work
    for f in ["bench.nuon" "watch.nuon"] {
        let at = ($bench | path join $f)
        if ($at | path exists) { cp $at ($work | path join $f) }
    }
    let manifest = ($bench | path join "preflight" "package.nuon")
    if ($manifest | path exists) {
        mkdir ($work | path join "preflight")
        cp $manifest ($work | path join "preflight" "package.nuon")
    }
    let listed = (open ($bench | path join "bench.nuon"))
    for s in $listed.steps {
        let step = ($bench | path join $s.label)
        if ($step | path type) == "dir" and not (glob ($step | path join "run_*") | is-empty) {
            gauge read batch $step --label $s.label --out ($work | path join $s.label)
        }
    }
}

# The candidate's record the check reads: the file given, held to the record's SHA-256
def candidate-file [r: record, given: string, work: path]: nothing -> record<file: string, problems: list<string>> {
    if $given != "" {
        let sha = (open --raw $given | hash sha256)
        let problems = (if $sha != $r.candidate.sha256 { [$"the candidate's record ($given) has SHA-256 ($sha) where the record names ($r.candidate.sha256)"] } else { [] })
        return { file: ($given | path expand), problems: $problems }
    }
    let file = ($work | path join "candidate.nuon")
    $r.candidate | reject -o file sha256 | to nuon --indent 2 | save --raw -f $file
    { file: $file, problems: [$"the candidate's record was not reopened: the record's own copy of it stands in"] }
}

# Where the record's stored answers differ from those derived again, each item with both
def history-of [stored: record, fresh: record]: nothing -> list<any> {
    let runs = ($fresh.runs | each {|f|
        let s = ($stored.runs | where {|x| $x.step == $f.step and $x.run == $f.run } | get -o 0)
        let name = (matrix run-name $f)
        if $s == null { return [{ item: $name, stored: null, derived: "present" }] }
        [
            (if ($s | get -o standing) != $f.standing { { item: $"($name)'s standing", stored: $s.standing, derived: $f.standing } })
            (if ($s | get -o verdict.pass) != ($f | get -o verdict.pass) { { item: $"($name)'s verdict", stored: ($s | get -o verdict.pass), derived: ($f | get -o verdict.pass) } })
            (if ($s | get -o verdict.median_us) != ($f | get -o verdict.median_us) { { item: $"($name)'s median", stored: ($s | get -o verdict.median_us), derived: ($f | get -o verdict.median_us) } })
        ] | compact
    } | flatten)
    let gone = ($stored.runs | where {|s| ($fresh.runs | where {|x| $x.step == $s.step and $x.run == $s.run } | is-empty) } | each {|s| { item: (matrix run-name $s), stored: "present", derived: null } })
    let cases = ($fresh.cases | each {|f|
        let s = ($stored.cases | where case == $f.case | get -o 0)
        let met = {|c: any| if $c == null { null } else if $c.kind == "control" { $c.reading.met } else if $c.kind == "acceptance" { $c.reading.passed } else { $c.reading.read } }
        [
            (if (do $met $s) != (do $met $f) { { item: $"($f.case)'s reading", stored: (do $met $s), derived: (do $met $f) } })
            (if ($s | get -o missing | default [] | length) != ($f.missing | length) { { item: $"($f.case)'s missing runs", stored: ($s | get -o missing | default [] | length), derived: ($f.missing | length) } })
        ] | compact
    } | flatten)
    let bench = (if $stored.bench.problems != $fresh.bench.problems { [{ item: "the bench's problems", stored: $stored.bench.problems, derived: $fresh.bench.problems }] } else { [] })
    $runs ++ $gone ++ $cases ++ $bench
}

# A record derived again from its reopened inputs, checked, its ledger recomputed
export def check-of [r: any, bench: path, work: path, --inventory: string = "", --candidate: string = ""]: nothing -> record {
    let schema = (schema-problems $r)
    if not ($schema | is-empty) { return { problems: $schema, ledger: [], verdicts: null, history: [], reopened: null, record: null } }
    let spec = (try { spec row $JAB $r.target } catch { null })
    if $r.target not-in $TARGETS or $spec == null { return { problems: [$"the record's target, ($r.target), is no target of the qualification's matrix"], ledger: [], verdicts: null, history: [], reopened: null, record: null } }
    let bench = ($bench | path expand)
    if not ($bench | path join "bench.nuon" | path exists) { error make { msg: $"($bench) holds no bench.nuon, so it is no bench run's directory" } }
    let held = (reopened $bench $inventory)
    rebuilt $bench $work
    let cand = (candidate-file $r $candidate $work)
    let fresh = (record record-of $work $cand.file $r.target)
    let tag = (matrix tag-state $fresh.candidate.tag $fresh.candidate.jab)
    let ledger = (matrix ledger-of $fresh $tag ($fresh.bench.problems ++ $fresh.conditions.problems ++ $held.problems ++ $cand.problems))
    let verdicts = (matrix verdicts-of $ledger)
    let problems = ($ledger | where state == "failed" | each {|x| $x.problems | each {|p| $"($x.row): ($p)" } } | flatten)
    { problems: $problems, ledger: $ledger, verdicts: $verdicts, history: (history-of $r $fresh), reopened: { inventory: (if $inventory == "" { null } else { $inventory | path expand }), checked: $held.checked, problems: $held.problems }, record: $fresh }
}

# A record checked: derived again from its bench's kept inputs into `out`, its verdicts printed
export def main [record: path, --bench: string = "", --inventory: string = "", --candidate: string = "", --out: string = ""] {
    let r = (open $record)
    let out = (if $out == "" { $record | path expand | path dirname | path join "check" } else { $out | path expand })
    if ($out | path join $CHECK | path exists) { error make { msg: $"($out) holds a check; a check is written once into an out" } }
    let bench_dir = (if $bench == "" { $r.bench.dir } else { $bench })
    let c = (check-of $r $bench_dir ($out | path join "bench") --inventory $inventory --candidate $candidate)
    if $c.record != null { $c.record | to nuon --indent 1 | save --raw ($out | path join $RECORD) }
    { checked: ($record | path expand), checked_sha256: (open --raw $record | hash sha256), bench: ($bench_dir | path expand), record: (if $c.record == null { null } else { $out | path join $RECORD }), problems: $c.problems, ledger: $c.ledger, verdicts: $c.verdicts, history: $c.history, reopened: $c.reopened } | to nuon --indent 1 | save --raw ($out | path join $CHECK)
    for h in $c.history { print $"qualification: the record's ($h.item) reads ($h.stored | to nuon), derived again ($h.derived | to nuon)" }
    for p in $c.problems { print $"qualification: ($p)" }
    if $c.verdicts != null {
        print $"qualification: ($r.target): ($c.verdicts.subset.verdict); ($c.verdicts.final.verdict)"
    }
    print $"qualification: ($out | path join $CHECK)"
    if not ($c.problems | is-empty) { error make { msg: $"($record): ($c.problems | length) problems" } }
}
