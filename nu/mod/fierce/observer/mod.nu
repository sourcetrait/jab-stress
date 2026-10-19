# The measures, each a name and its statistic's path in a run's summary
export const MEASURES = [
    [measure, path];
    ["critical path median", [critical median]]
    ["drawing median", [draw median]]
    ["flip median", [flip median]]
    ["acceptance interval median", [acceptance_interval median]]
    ["acceptance interval 95th", [acceptance_interval p95]]
    ["completion interval median", [completion_interval median]]
    ["completion interval 95th", [completion_interval p95]]
]

# A list's median by nearest rank, null for no values
def median-of [values: list<number>]: nothing -> any {
    let n = ($values | length)
    if $n == 0 { return null }
    $values | sort | get ((($n * 0.5) | math ceil) - 1)
}

# A run's statistic of a measure from its whole-run summary, or null
def statistic [whole: any, path: list<string>]: nothing -> any {
    $whole | get -o ($path | into cell-path)
}

# The shim's effect over a probed and a plain arm, each measure judged
export def shim-effect [probed: list<record>, plain: list<record>]: nothing -> record<measures: list<any>, admissible: bool, problems: list<string>> {
    let empty = ([[probed $probed] [plain $plain]] | where {|a| ($a.1 | is-empty) } | each {|a| $"the ($a.0) arm holds no run" })
    let measures = ($MEASURES | each {|m|
        let read = {|arm: string, runs: list<record>| $runs | each {|r| { arm: $arm, name: $r.name, value: (statistic $r.whole $m.path) } } }
        let values = ((do $read probed $probed) ++ (do $read plain $plain))
        let missing = ($values | where value == null | each {|v| $"($v.arm) run ($v.name) holds no ($m.measure)" })
        let of = {|arm: string| $values | where {|v| $v.arm == $arm and $v.value != null } | get value }
        let range = {|arm: string| let v = (do $of $arm); if ($v | is-empty) { null } else { ($v | math max) - ($v | math min) } }
        let a = (median-of (do $of probed))
        let b = (median-of (do $of plain))
        let ranges = ([(do $range probed) (do $range plain)] | compact)
        let effect = (if $a == null or $b == null { null } else { $a - $b })
        let noise = (if ($ranges | length) < 2 { null } else { ($ranges | math max) / 2 })
        let within = (if (not ($missing | is-empty)) or $effect == null or $noise == null { false } else { ($effect | math abs) <= $noise })
        { measure: $m.measure, probed: $a, plain: $b, effect: $effect, noise: $noise, within: $within, runs: $values, problems: $missing }
    })
    let problems = ($empty ++ ($measures | get problems | flatten))
    { measures: ($measures | reject problems), admissible: (($problems | is-empty) and ($measures | all {|m| $m.within })), problems: $problems }
}
