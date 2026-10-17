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
# `main <readings> <out>` writes decision.nuon in `out`; `main holds
# <scratch>` runs the selector's own fixtures over synthetic readings.

# This file, whose SHA-256 a decision records.
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

# The holds' clean comparison written as a readings record, for a run of
# the selector over it.
def "main sample" [readings: path] {
    base-readings | to nuon --indent 1 | save --raw $readings
    print $"timing sample: ($readings)"
}

def main [readings: path, out: path] {
    let raw = (open --raw $readings | into binary)
    let decision = (decide ($raw | decode | from nuon) | merge { readings_sha256: ($raw | hash sha256), selector_sha256: (open --raw $SELF | hash sha256) })
    mkdir $out
    $decision | to nuon --indent 1 | save --raw -f ($out | path join "decision.nuon")
    print $"timing select: ($decision.outcome), the contract ($decision.contract)"
    for b in $decision.blockers { print $"  blocker: ($b)" }
}

# A synthetic run, the box's unprobed fps run on 1KA1 under P0 by
# default, its legs' critical paths and presented 95ths those given.
def run-of [fields: record]: nothing -> record {
    {
        id: "r", host: "box", target: "1ka1", workload: "fps", kernel: "P0", order: "prepare", timing: false,
        probed: false, backend: "offscreen", build: "frozen", battery: "b", position: 0, valid: true,
        k_violations: 0, legs: [], submission_age_median_ms: 5.0, late_wakes: 0, catch_ups: 0,
        shown_p95_ms: null, presented_median_ms: null, presented_p95_ms: null, d_median_ms: null, phases: null,
    } | merge $fields
}

# The legs of a synthetic fps run: the late-frame legs and the factory's
# own, each its critical path and its presented 95th.
def legs-at [critical: float, presented: float]: nothing -> list<any> {
    $LATE_LEGS ++ [factory] | each {|l| { leg: $l, critical_median_ms: $critical, presented_p95_ms: $presented } }
}

# Six runs of a condition on a host and target, their figures 0.01 ms
# apart, so each arm's range is 0.05 and its N 0.025.
def six [host: string, target: string, fields: record]: nothing -> list<any> {
    0..5 | each {|i|
        let x = ($i * 0.01)
        let workload = ($fields | get -o workload | default "fps")
        let id = $"($host)-($target)-($workload)-($fields | get -o kernel | default 'P0')-($fields | get -o order | default 'prepare')-(if ($fields | get -o timing | default false) { 'on' } else { 'off' })-(if ($fields | get -o probed | default false) { 'probed' } else { 'unprobed' })-($i)"
        let figures = (if $workload == "fps" {
            { legs: (legs-at (10.0 + $x) (17.0 + $x)), shown_p95_ms: (if ($fields | get -o probed | default false) { 33.0 + $x } else { null }) }
        } else {
            let timed = ($fields | get -o timing | default false)
            { presented_median_ms: (16.7 + $x), presented_p95_ms: (17.5 + $x), d_median_ms: (if $timed { 5.0 + $x } else { null }), phases: (if $timed { { work: 5.0, wait: 11.0, call: 1.5 } } else { null }) }
        })
        run-of ({ id: $id, host: $host, target: $target, position: $i } | merge $figures | merge $fields)
    }
}

# Every condition of the box's comparison on both targets: fps P0 and P2
# unprobed and probed, walk's P0 await and P2 prepare TIMING off, and
# walk's three TIMING-on arms; each rule's shim control and each on
# arm's TIMING control passing; calibrated; checks exact.
def base-readings []: nothing -> record {
    let runs = ($TARGETS | each {|t|
        [
            { kernel: "P0" } { kernel: "P2" } { kernel: "P0", probed: true } { kernel: "P2", probed: true }
            { workload: "walk", kernel: "P0", order: "await" } { workload: "walk", kernel: "P2", order: "prepare" }
            { workload: "walk", kernel: "P0", order: "await", timing: true } { workload: "walk", kernel: "P2", order: "await", timing: true }
            { workload: "walk", kernel: "P2", order: "prepare", timing: true }
        ] | each {|c| six "box" $t $c } | flatten
    } | flatten)
    let controls = ($TARGETS | each {|t|
        let shims = ([P0 P2] | each {|k| { kind: "shim", host: "box", target: $t, kernel: $k, order: "prepare", backend: "offscreen", build: "frozen", arm: $"fps ($k) probed", passing: true } })
        let timings = ([[P0 await] [P2 await] [P2 prepare]] | each {|a| { kind: "timing", host: "box", target: $t, kernel: $a.0, order: $a.1, backend: "offscreen", build: "frozen", arm: $"walk ($a.0) ($a.1)", passing: true } })
        $shims ++ $timings
    } | flatten)
    {
        strategy: "reordered",
        checks: { function_cases: true, model: true, cadence_fixtures: true },
        calibration: { state: "calibrated", eps: 1000, qualifying: { "1ka1": 1200, "1kb1": 1300 } },
        runs: $runs, controls: $controls, host_limits: [],
    }
}

# The readings with every run `pick` takes changed by `change`.
def runs-changed [readings: record, pick: closure, change: closure]: nothing -> record {
    $readings | update runs ($readings.runs | each {|r| if (do $pick $r) { do $change $r } else { $r } })
}

# The readings with every run `pick` takes removed.
def runs-dropped [readings: record, pick: closure]: nothing -> record {
    $readings | update runs ($readings.runs | where {|r| not (do $pick $r) })
}

# A run's legs with `field` raised by `by` on one leg.
def leg-raised [r: record, leg: string, field: string, by: float]: nothing -> record {
    $r | update legs ($r.legs | each {|l| if $l.leg == $leg { $l | update $field (($l | get $field) + $by) } else { $l } })
}

# The selector's own fixtures over synthetic readings, each case's
# failure raised with its name, run in a loop so a failure raises alone:
# the clean comparison chosen, each rule's verdict, and the plan's nine
# holds (JointTiming's selector).
def "main holds" [scratch: path] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    mkdir $scratch
    let fail = {|name: string, why: string| error make { msg: $"timing holds: ($name): ($why)" } }
    let base = (base-readings)
    let p2_fps = {|r| $r.workload == "fps" and $r.kernel == "P2" and (not $r.probed) }
    let cases = [
        { name: "chosen", readings: $base, check: {|d| $d.outcome == "chosen" and $d.contract == "met" and ($d.walk.phases | all {|p| $p.evidence == "admissible" }) } }
        { name: "regression", readings: (runs-changed $base {|r| (do $p2_fps $r) and $r.target == "1kb1" } {|r| leg-raised $r "yard" "critical_median_ms" 0.5 }), check: {|d| $d.outcome == "regressing" and ($d.regression | where {|r| $r.regressing } | get leg) == ["yard"] } }
        { name: "regression floor", readings: (runs-changed $base {|r| do $p2_fps $r } {|r| leg-raised $r "up" "critical_median_ms" 0.2 }), check: {|d| $d.outcome == "chosen" and not ($d.regression | any {|r| $r.regressing }) } }
        { name: "regression within noise", readings: (runs-changed $base {|r| (do $p2_fps $r) and $r.target == "1ka1" } {|r| leg-raised $r "factory" "critical_median_ms" (0.3 + ($r.position - 2.5) * 0.3) }), check: {|d| $d.outcome == "chosen" and not ($d.regression | any {|r| $r.regressing }) } }
        { name: "no fps comparison", readings: (runs-dropped $base {|r| (do $p2_fps $r) and $r.target == "1kb1" }), check: {|d| $d.outcome == "insufficient" and ($d.blockers | any {|b| $b | str contains "1kb1" }) } }
        { name: "display worse", readings: (runs-changed $base {|r| $r.workload == "fps" and $r.kernel == "P2" and $r.probed and $r.target == "1ka1" } {|r| $r | update shown_p95_ms ($r.shown_p95_ms + 0.3) }), check: {|d| $d.outcome == "regressing" and ($d.presentation.display | where {|r| $r.worse } | get target) == ["1ka1"] } }
        { name: "presentation", readings: (runs-changed $base {|r| (do $p2_fps $r) and $r.target == "1ka1" } {|r| leg-raised $r "pressure" "presented_p95_ms" 0.3 }), check: {|d| $d.outcome == "regressing" and ($d.presentation.guest | where {|r| $r.worse } | get leg) == ["pressure"] and not ($d.regression | any {|r| $r.regressing }) } }
        { name: "noise gate", readings: (runs-changed $base {|r| (do $p2_fps $r) and $r.target == "1ka1" and $r.position == 5 } {|r| leg-raised $r "start" "critical_median_ms" 2.5 }), check: {|d| $d.outcome == "insufficient" and not $d.noise.passed } }
        { name: "eps short", readings: ($base | update calibration.state "short"), check: {|d| $d.outcome == "insufficient" and not $d.calibration.calibrated } }
        { name: "checks", readings: ($base | update checks.model false), check: {|d| $d.outcome == "ineligible" } }
        { name: "K in fps", readings: (runs-changed $base {|r| (do $p2_fps $r) and $r.position == 3 } {|r| $r | update k_violations 1 }), check: {|d| $d.outcome == "ineligible" } }
        { name: "control scope", readings: ($base | update controls ($base.controls | each {|c| if $c.kind == "timing" and $c.kernel == "P2" and $c.order == "await" { $c | update kernel "P0" } else { $c } })), check: {|d| ($d.walk.phases | where {|p| $p.kernel == "P2" and $p.order == "await" } | all {|p| $p.evidence == "instrumented-only" }) and ($d.walk.phases | where {|p| $p.order == "prepare" } | all {|p| $p.evidence == "admissible" }) } }
        { name: "TIMING on refused", readings: (runs-dropped $base {|r| $r.workload == "walk" and $r.kernel == "P2" and $r.order == "prepare" and (not $r.timing) and $r.target == "1ka1" }), check: {|d| $d.outcome == "insufficient" and ($d.walk.gate | where target == "1ka1" | first | get state) == "insufficient" and not ($d.walk.gate | where target == "1ka1" | first | get refused | is-empty) } }
        { name: "off supplies the gate", readings: ($base | update controls ($base.controls | where kind == "shim")), check: {|d| $d.outcome == "chosen" and ($d.walk.gate | all {|g| $g.state == "admissible" }) and ($d.walk.phases | all {|p| $p.evidence == "instrumented-only" }) } }
        { name: "probed walk refused", readings: (runs-changed $base {|r| $r.workload == "walk" and $r.kernel == "P2" and $r.order == "prepare" and (not $r.timing) and $r.target == "1kb1" } {|r| $r | update probed true }), check: {|d| $d.outcome == "insufficient" and ($d.walk.gate | where target == "1kb1" | first | get state) == "insufficient" } }
        { name: "off invalid", readings: (runs-changed $base {|r| $r.workload == "walk" and $r.kernel == "P0" and (not $r.timing) and $r.position == 0 } {|r| $r | update valid false }), check: {|d| $d.outcome == "insufficient" and ($d.walk.gate | all {|g| $g.state == "insufficient" }) } }
        { name: "off noise", readings: (runs-changed $base {|r| $r.workload == "walk" and $r.kernel == "P2" and (not $r.timing) and $r.position == 5 and $r.target == "1ka1" } {|r| $r | update presented_p95_ms ($r.presented_p95_ms + 2.5) }), check: {|d| $d.outcome == "insufficient" and ($d.noise.over | any {|o| $o.what == "walk 95th" }) } }
        { name: "walk fails", readings: (runs-changed $base {|r| $r.workload == "walk" and $r.kernel == "P2" and (not $r.timing) and $r.target == "1kb1" } {|r| $r | update presented_median_ms ($r.presented_median_ms + 0.5) }), check: {|d| $d.outcome == "walk_failed" and ($d.walk.gate | where {|r| $r.fails } | get target) == ["1kb1"] } }
        { name: "display without a control", readings: ($base | update controls ($base.controls | where {|c| not ($c.kind == "shim" and $c.kernel == "P2" and $c.target == "1ka1") })), check: {|d| $d.outcome == "insufficient" and ($d.presentation.display | where target == "1ka1" | first | get state) == "insufficient" } }
        { name: "host limit inadmissible", readings: ($base | update controls ($base.controls | where kind == "timing") | update host_limits [{ host: "box", target: "1ka1", admissible: false, limit: true } { host: "box", target: "1kb1", admissible: false, limit: true }]), check: {|d| $d.outcome == "insufficient" and ($d.presentation.display | all {|r| $r.state == "insufficient" }) } }
        { name: "host limit admissible", readings: ($base | update controls ($base.controls | where kind == "timing") | update host_limits [{ host: "box", target: "1ka1", admissible: true, limit: true } { host: "box", target: "1kb1", admissible: true, limit: true }]), check: {|d| $d.outcome == "chosen" and ($d.presentation.display | all {|r| $r.state == "out" }) } }
        { name: "his host without probed runs", readings: ($base | update runs ($base.runs ++ ($TARGETS | each {|t| [{ kernel: "P0" } { kernel: "P2" }] | each {|c| six "masa" $t $c } | flatten } | flatten))), check: {|d| $d.outcome == "insufficient" and ($d.presentation.display | where host == "masa" | all {|r| $r.state == "blocked" }) and ($d.blockers | any {|b| $b starts-with "masa" }) } }
        { name: "his host's admissible limit", readings: ($base | update runs ($base.runs ++ ($TARGETS | each {|t| [{ kernel: "P0" } { kernel: "P2" } { kernel: "P0", probed: true } { kernel: "P2", probed: true }] | each {|c| six "masa" $t $c } | flatten } | flatten)) | update host_limits [{ host: "masa", target: "1ka1", admissible: true, limit: true } { host: "masa", target: "1kb1", admissible: true, limit: true }]), check: {|d| $d.outcome == "chosen" and ($d.presentation.display | where host == "masa" | all {|r| $r.state == "out" }) } }
        { name: "a box control for his host", readings: ($base | update runs ($base.runs ++ ($TARGETS | each {|t| [{ kernel: "P0" } { kernel: "P2" } { kernel: "P0", probed: true } { kernel: "P2", probed: true }] | each {|c| six "masa" $t $c } | flatten } | flatten))), check: {|d| $d.outcome == "insufficient" and ($d.presentation.display | where host == "masa" | all {|r| $r.state == "insufficient" }) } }
        { name: "a later candidate's control", readings: ($base | update controls ($base.controls | each {|c| if $c.kind == "shim" and $c.target == "1kb1" { $c | update build "qualification" } else { $c } })), check: {|d| $d.outcome == "insufficient" and ($d.presentation.display | where target == "1kb1" | first | get state) == "insufficient" } }
        { name: "K in a TIMING-on run", readings: (runs-changed $base {|r| $r.workload == "walk" and $r.kernel == "P2" and $r.timing and $r.position == 2 } {|r| $r | update k_violations 2 }), check: {|d| $d.outcome == "ineligible" and ($d.walk.gate | all {|g| $g.state == "admissible" and not $g.fails }) } }
    ]
    for c in $cases {
        let d = (decide $c.readings)
        if not (do $c.check $d) { do $fail $c.name $"decided ($d.outcome): ($d | reject regression | to nuon | str substring 0..300)" }
    }
    print $"timing holds: ($cases | length) cases"
    print "timing holds: ok"
}
