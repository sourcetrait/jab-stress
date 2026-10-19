# JointTiming's selector (TimingSelector): the selection rule applied to
# one readings record and written as one decision record. The readings
# carry the comparison as each reader gives it: P2's correctness checks,
# eps's calibration, every run's figures with its host, target,
# workload, kernel, loop order, TIMING flag, probe, backend, and build,
# the controls with their scopes, and each host's host-limit findings.
# An arm is one condition's runs; its figure the median of its runs'
# statistic; d the compared arm's figure less its base's, P2's less P0's;
# N half the larger of the two arms' ranges of that statistic. The
# record names each predicate's figures and evidence, the noise gate,
# and the outcome, in the plan's order: ineligible, insufficient,
# regressing (the critical path or the presentation), the second
# workload failing, chosen; only chosen meets the contract.
#
# `main <readings> <out>` writes decision.nuon in `out`.

use ../../../jab/nu/mod/identity

# This file, from which a decision's selector finds its checkout.
const SELF = (path self)
# The late-frame legs the guest's presentation predicate reads.
const LATE_LEGS = [start up yard pressure]
# A regression's floor: a critical-path d must pass both its N and this.
const REGRESSION_FLOOR_MS = 0.25
# The noise gate: a deciding statistic's N past this is insufficient.
const NOISE_GATE_MS = 1.0
# The targets every predicate is judged on.
const TARGETS = ["1ka1" "1kb1"]
# What scopes a control: the arm's own host, target, kernel, loop order,
# backend, and build.
const SCOPE = [host target kernel order backend build]

# The runs of one condition: every field `cond` names equal.
def arm-of [runs: list<any>, cond: record]: nothing -> list<any> {
    $runs | where {|r| $cond | items {|k, v| ($r | get -o $k) == $v } | all {|x| $x } }
}

# An arm's figure for a statistic, the median of its runs' values, beside
# their range and their count; a run without the statistic left out.
def figure-of [runs: list<any>, stat: closure]: nothing -> record {
    let values = ($runs | each {|r| do $stat $r } | where {|v| $v != null })
    if ($values | is-empty) { return { figure: null, range: null, count: 0 } }
    { figure: ($values | math median), range: (($values | math max) - ($values | math min)), count: ($values | length) }
}

# Two arms compared on a statistic: each one's figure, d the compared
# less the base, and N half the larger range; d and N null where either
# arm has no figure.
def compare [base: list<any>, compared: list<any>, stat: closure]: nothing -> record {
    let b = (figure-of $base $stat)
    let c = (figure-of $compared $stat)
    if $b.figure == null or $c.figure == null { return { base: $b.figure, compared: $c.figure, d: null, n: null, runs: [$b.count $c.count] } }
    { base: $b.figure, compared: $c.figure, d: ($c.figure - $b.figure), n: (([$b.range $c.range] | math max) / 2.0), runs: [$b.count $c.count] }
}

# An arm's scope, from its first run: the fields a control must match.
def scope-of [runs: list<any>]: nothing -> record {
    let r = ($runs | first)
    $SCOPE | reduce --fold {} {|k, acc| $acc | insert $k ($r | get -o $k) }
}

# Whether a passing control of `kind` applies to an arm: one whose every
# scope field is the arm's.
def admitted [controls: list<any>, kind: string, runs: list<any>]: nothing -> bool {
    if ($runs | is-empty) { return false }
    let scope = (scope-of $runs)
    $controls | any {|c| $c.kind == $kind and $c.passing and ($SCOPE | all {|k| ($c | get -o $k) == ($scope | get $k) }) }
}

# The hosts the readings hold runs of.
def hosts-of [readings: record]: nothing -> list<string> {
    $readings.runs | get host | uniq
}

# P2's eligibility: its checks exact and no K violation in any P2 run,
# fps's probed and unprobed and walk's TIMING on and off alike.
def eligibility [readings: record]: nothing -> record {
    let checks = ([function_cases model cadence_fixtures] | where {|k| ($readings.checks | get -o $k) != true } | each {|k| $"P2's ($k) not exact" })
    let violated = ($readings.runs | where {|r| $r.kernel == "P2" and $r.k_violations > 0 } | each {|r| $"K violated ($r.k_violations) times in ($r.id)" })
    let why = ($checks ++ $violated)
    { eligible: ($why | is-empty), why: $why }
}

# fps's unprobed arm of one kernel on a host and target.
def fps-arm [runs: list<any>, host: string, target: string, kernel: string]: nothing -> list<any> {
    arm-of $runs { host: $host, target: $target, workload: "fps", kernel: $kernel, probed: false }
}

# A leg's statistic of a run, null where the run has no such leg.
def leg-stat [r: record, leg: string, field: string]: nothing -> any {
    $r | get -o legs | default [] | where {|l| $l.leg == $leg } | get -o 0 | default {} | get -o $field
}

# The regression rule on each host and target's unprobed fps runs: a leg
# regresses when P2's critical-path d passes both its N and the floor.
def regression [readings: record]: nothing -> list<any> {
    hosts-of $readings | each {|h| $TARGETS | each {|t|
        let base = (fps-arm $readings.runs $h $t "P0")
        let comp = (fps-arm $readings.runs $h $t "P2")
        let legs = ($base ++ $comp | each {|r| $r | get -o legs | default [] | get leg } | flatten | uniq)
        $legs | each {|leg|
            let c = (compare $base $comp {|r| leg-stat $r $leg "critical_median_ms" })
            $c | merge { host: $h, target: $t, leg: $leg, regressing: ($c.d != null and $c.d > $c.n and $c.d > $REGRESSION_FLOOR_MS) }
        }
    } | flatten } | flatten
}

# The guest's presentation on each host and target's unprobed fps runs:
# on the late-frame legs P2's presented-interval 95th at most P0's plus N.
def presentation-guest [readings: record]: nothing -> list<any> {
    hosts-of $readings | each {|h| $TARGETS | each {|t|
        let base = (fps-arm $readings.runs $h $t "P0")
        let comp = (fps-arm $readings.runs $h $t "P2")
        $LATE_LEGS | each {|leg|
            let c = (compare $base $comp {|r| leg-stat $r $leg "presented_p95_ms" })
            $c | merge { host: $h, target: $t, leg: $leg, worse: ($c.d != null and $c.compared > ($c.base + $c.n)) }
        }
    } | flatten } | flatten
}

# Each host's display side on each target, from its probed fps runs:
# blocked with no probed condition, a named input blocker; out on an
# admissible host-limit finding, the decision guest-side; admissible when
# each rule's readings carry a passing shim control of their own scope,
# the shown-frame 95th compared; else insufficient, a host-limit claim on
# inadmissible runs among it.
def presentation-display [readings: record]: nothing -> list<any> {
    hosts-of $readings | each {|h| $TARGETS | each {|t|
        let base = (arm-of $readings.runs { host: $h, target: $t, workload: "fps", kernel: "P0", probed: true })
        let comp = (arm-of $readings.runs { host: $h, target: $t, workload: "fps", kernel: "P2", probed: true })
        let limits = ($readings.host_limits | where {|l| $l.host == $h and $l.target == $t and $l.limit })
        let row = { host: $h, target: $t, base: null, compared: null, d: null, n: null, worse: false }
        if ($base | is-empty) and ($comp | is-empty) {
            $row | merge { state: "blocked", why: "no probed condition among the runs" }
        } else if ($limits | any {|l| $l.admissible }) {
            $row | merge { state: "out", why: "a host limit on admissible runs: the decision guest-side" }
        } else if (admitted $readings.controls "shim" $base) and (admitted $readings.controls "shim" $comp) {
            let c = (compare $base $comp {|r| $r.shown_p95_ms })
            $row | merge $c | merge { state: "admissible", why: "", worse: ($c.d != null and $c.compared > ($c.base + $c.n)) }
        } else if not ($limits | is-empty) {
            $row | merge { state: "insufficient", why: "a host limit claimed on inadmissible runs" }
        } else {
            $row | merge { state: "insufficient", why: "no applicable passing shim control for each rule's readings" }
        }
    } } | flatten
}

# walk's arm of a kernel and order on a host and target, TIMING off and
# unprobed, the gate's own input: a TIMING-on run and a probed run are
# never its, whatever is offered.
def walk-off-arm [runs: list<any>, host: string, target: string, kernel: string, order: string]: nothing -> list<any> {
    arm-of $runs { host: $host, target: $target, workload: "walk", kernel: $kernel, order: $order, timing: false, probed: false }
}

# The second workload's gate on each host and target, by the strategy:
# reordered, P2 prepare's walk figures at most P0 await's plus N, median
# and 95th, on the TIMING-off unprobed arms alone, a missing arm or an
# invalid run insufficient; tradeoff, P2 await's figures reported, held
# to nothing.
def walk-gate [readings: record]: nothing -> list<any> {
    let order = (if $readings.strategy == "reordered" { "prepare" } else { "await" })
    hosts-of $readings | each {|h|
        if ($readings.runs | where {|r| $r.host == $h and $r.workload == "walk" } | is-empty) { return [] }
        $TARGETS | each {|t|
            let base = (walk-off-arm $readings.runs $h $t "P0" "await")
            let comp = (walk-off-arm $readings.runs $h $t "P2" $order)
            let offered = ($readings.runs | where {|r| $r.host == $h and $r.target == $t and $r.workload == "walk" and $r.kernel == "P2" and $r.order == $order and ($r.timing or $r.probed) })
            let row = { host: $h, target: $t, order: $order, median: null, p95: null, refused: ($offered | get id), fails: false }
            if ($base | is-empty) or ($comp | is-empty) {
                $row | merge { state: "insufficient", why: "an arm the strategy reads has no TIMING-off unprobed run" }
            } else if ($base ++ $comp | any {|r| not $r.valid }) {
                $row | merge { state: "insufficient", why: "an invalid run in an arm the strategy reads" }
            } else {
                let median = (compare $base $comp {|r| $r.presented_median_ms })
                let p95 = (compare $base $comp {|r| $r.presented_p95_ms })
                let fails = ($readings.strategy == "reordered" and (($median.compared > ($median.base + $median.n)) or ($p95.compared > ($p95.base + $p95.n))))
                $row | merge { state: "admissible", why: "", median: $median, p95: $p95, fails: $fails }
            }
        }
    } | flatten
}

# Each TIMING-on walk arm's D and phases on each host and target: the
# runs' medians, admissible under a passing TIMING control of the arm's
# own scope, else instrumented-only.
def walk-phases [readings: record]: nothing -> list<any> {
    let arms = ($readings.runs | where {|r| $r.workload == "walk" and $r.timing and (not $r.probed) } | each {|r| { host: $r.host, target: $r.target, kernel: $r.kernel, order: $r.order } } | uniq)
    $arms | each {|a|
        let runs = (arm-of $readings.runs ($a | merge { workload: "walk", timing: true, probed: false }))
        let d = (figure-of $runs {|r| $r.d_median_ms })
        $a | merge { d_ms: $d.figure, evidence: (if (admitted $readings.controls "timing" $runs) { "admissible" } else { "instrumented-only" }) }
    }
}

# The noise gate over every deciding comparison: each N past the gate.
def noise-gate [regressions: list<any>, guest: list<any>, display: list<any>, walk: list<any>]: nothing -> record {
    let critical = ($regressions | where {|r| $r.n != null } | each {|r| { what: $"critical path, ($r.leg)", host: $r.host, target: $r.target, n: $r.n } })
    let presented = ($guest | where {|r| $r.n != null } | each {|r| { what: $"presented 95th, ($r.leg)", host: $r.host, target: $r.target, n: $r.n } })
    let shown = ($display | where {|r| $r.state == "admissible" and $r.n != null } | each {|r| { what: "shown 95th", host: $r.host, target: $r.target, n: $r.n } })
    let walked = ($walk | where {|r| $r.state == "admissible" } | each {|r| [{ what: "walk median", host: $r.host, target: $r.target, n: $r.median.n } { what: "walk 95th", host: $r.host, target: $r.target, n: $r.p95.n }] } | flatten)
    let rows = ($critical ++ $presented ++ $shown ++ $walked)
    let over = ($rows | where {|r| $r.n > $NOISE_GATE_MS })
    { passed: ($over | is-empty), over: $over }
}

# The decision over a readings record: every predicate's rows, the
# noise gate, the blockers, and the outcome in the plan's order.
export def decide [readings: record]: nothing -> record {
    let eligible = (eligibility $readings)
    let regressions = (regression $readings)
    let guest = (presentation-guest $readings)
    let display = (presentation-display $readings)
    let walk = (walk-gate $readings)
    let phases = (walk-phases $readings)
    let noise = (noise-gate $regressions $guest $display $walk)
    let calibrated = ($readings.calibration.state != "short")
    let missing = ($TARGETS | where {|t| ($regressions | where {|r| $r.host == "box" and $r.target == $t and $r.d != null } | is-empty) } | each {|t| $"the box's fps comparison on ($t)" })
    let short_walk = ($walk | where state == "insufficient")
    let short_display = ($display | where {|r| $r.state in ["insufficient" "blocked"] })
    let insufficient = ((not $calibrated) or (not $noise.passed) or (not ($missing | is-empty)) or (not ($short_walk | is-empty)) or (not ($short_display | is-empty)))
    let regressing = (($regressions | any {|r| $r.regressing }) or ($guest | any {|r| $r.worse }) or ($display | any {|r| $r.worse }))
    let walk_failed = ($walk | any {|r| $r.fails })
    let outcome = (if not $eligible.eligible { "ineligible" } else if $insufficient { "insufficient" } else if $regressing { "regressing" } else if $walk_failed { "walk_failed" } else { "chosen" })
    {
        strategy: $readings.strategy,
        calibration: ($readings.calibration | merge { calibrated: $calibrated }),
        eligibility: $eligible,
        regression: $regressions,
        presentation: { guest: $guest, display: $display },
        walk: { gate: $walk, phases: $phases },
        noise: $noise,
        blockers: (($display | where state == "blocked" | each {|r| $"($r.host) on ($r.target): ($r.why)" }) ++ $missing),
        outcome: $outcome,
        contract: (if $outcome == "chosen" { "met" } else { "unmet" }),
    }
}

def main [readings: path, out: path] {
    let raw = (open --raw $readings | into binary)
    let decision = (decide ($raw | decode | from nuon) | merge { readings_sha256: ($raw | hash sha256), selector: (identity reader [($SELF | path dirname | path join .. .. | path expand)]) })
    mkdir $out
    $decision | to nuon --indent 1 | save --raw -f ($out | path join "decision.nuon")
    print $"timing select: ($decision.outcome), the contract ($decision.contract)"
    for b in $decision.blockers { print $"  blocker: ($b)" }
}
