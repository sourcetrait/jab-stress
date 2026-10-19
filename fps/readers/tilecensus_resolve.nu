# TileCensus's run binding (GaugeStanding, CensusRunBinding) in a nu of its
# own, called by tilecensus.nu: the gauge loaded beside census.nu's parse
# slows every command that takes a closure in proportion to the code loaded
# (41 s against 5.4 s on one run's log), so the census is read where the gauge
# is not. For each request, a report and a run number in it: the run
# refused unless its capture is complete and valid; else its directory the
# one whose identity file binds to the run's recorded SHA-256, through
# `gauge identity of` over the report's run-dirs, the identity's seed
# the run's; else refused. `nu tilecensus_resolve.nu <requests as NUON>`
# prints the answers as NUON.

use ../../../jab/kit/fierce/nu/mod/gauge

def main [requests: string] {
    $requests | from nuon | each {|q|
        let g = (open $q.report)
        let r = ($g.runs | where run == $q.run | first)
        { report: $q.report, run: $q.run } | merge (resolve $q.report $g $r)
    } | to nuon | print
}

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
