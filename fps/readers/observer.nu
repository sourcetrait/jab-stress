# observer.nu: ProbeRuns' observer control, the sdl shim's effect on the
# measures of the runs it was preloaded in (ProbeRuns.md's Observer
# controls). Two arms of runs, the shim preloaded in one and the one
# difference; each run's statistic of each measure read from its whole-run
# summary (gauge/measure's leg-summary); an arm's statistic the median of its
# runs' by nearest rank; the effect the probed arm's less the plain arm's;
# the noise half the larger of the two arms' ranges, an arm's range its
# greatest run's statistic less its least's; a measure within its noise
# when the effect's size is at most the noise. A probed reading stands for
# the unprobed program's presentation only when every measure is within
# its noise (`admissible`); otherwise its readings are instrumented-only.

# The measures, each a name and the cell path of its statistic in a run's
# whole-run summary: the critical path's, the drawing's, and the flip
# phase's medians, and the guest's presented interval's median and 95th.
export const MEASURES = [
    [measure, path];
    ["critical path median", [critical median]]
    ["drawing median", [draw median]]
    ["flip median", [flip median]]
    ["presented interval median", [flip_interval median]]
    ["presented interval 95th", [flip_interval p95]]
]

# A list's median by nearest rank, the gauge's statistics' rule; null for
# no values.
def median-of [values: list<number>]: nothing -> any {
    let n = ($values | length)
    if $n == 0 { return null }
    $values | sort | get ((($n * 0.5) | math ceil) - 1)
}

# A run's statistic of a measure, from its whole-run summary; null where
# the summary holds none.
def statistic [whole: any, path: list<string>]: nothing -> any {
    $whole | get -o ($path | into cell-path)
}

# The shim's effect over two arms, each a list of runs, a run its `name`
# and its whole-run summary `whole`: every measure's arm statistics, the
# effect, the noise, and whether the effect is within it; `problems`
# naming an arm with no run and each run lacking a statistic, a measure
# with a problem never within its noise; `admissible` when there is no
# problem and every measure is within its noise.
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
