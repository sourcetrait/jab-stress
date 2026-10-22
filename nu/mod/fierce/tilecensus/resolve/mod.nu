use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)

# Each run request resolved, the answers printed as NUON
export def main [requests: string]: nothing -> nothing {
    $requests | from nuon | each {|q|
        let g = (open $q.report)
        let r = ($g.runs | where run == $q.run | first)
        { report: $q.report, run: $q.run } | merge (resolve $q.report $g $r)
    } | to nuon | print
}

# A run's bound directory, or why it is refused
def resolve [report: string, g: record, r: record]: nothing -> record<dir: any, refused: list<string>> {
    let m = $r.measured
    if not ($m.complete and $m.valid) {
        return { dir: null, refused: [$"the capture complete ($m.complete) and valid ($m.valid), both owed"] }
    }
    let id = (gauge identity of $report $r $g.identity)
    let strength = ($id.binding | default {} | get -o strength)
    let dir = (if $id.file == null { null } else { $id.file | path dirname })
    if $strength != "sha256" {
        let passed = ($id.passed | each {|p| $"($p.dir) at ($p.strength)" } | str join "; ")
        return { dir: null, refused: [$"no identity file binds to the run's recorded SHA-256: read from ($id.from) at strength ($strength | default 'none'), passed over ($passed)"] }
    }
    let seed = ($id.identity | get -o mode.seed)
    if $seed != $r.seed {
        return { dir: null, refused: [$"the bound identity's seed ($seed) is not the run's ($r.seed)"] }
    }
    { dir: $dir, refused: [] }
}
