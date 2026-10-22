use (path self ../../../../../jab/nu/mod/identity)
use (path self ../../../../../jab/nu/mod/nutype)
use (path self ../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../runner/landing)

# The workbench, the checkout a decision's selector names
const STRESS = (path self ../../../.. | path expand)

# jab beside it, whose gauge measures every capture the selector reads
const JAB = (path self ../../../../../jab | path expand)

# The comparison as declared, and the model it is held to
const MATRIX = path self ../../../nuon/kernel/timing/matrix.nuon
const MODEL = path self ../../../type/kernel/timing/Matrix.nutype

# The late-frame legs the guest's presentation predicate reads
const LATE_LEGS = [start up yard pressure]

# A regression's floor: a critical-path d passes its N and this
const REGRESSION_FLOOR_MS = 0.25

# The noise gate: a deciding statistic's N past this is insufficient
const NOISE_GATE_MS = 1.0

# The calibration's least qualifying frames a target
const N_CAL = 1000

# eps's quantum and its cap, in ticks
const EPS_QUANTUM = 100
const EPS_CAP = 10000

# The calibration's states
const STATES = [calibrated capped short]

# The fields a run is matched to its declared condition by
const MATCH = [host target battery workload backend kernel order timing probed]

# The checks P2's eligibility binds, each to a landed run of the product
const CHECKS = [function_cases cadence_fixtures]

# Whether a value is a finite number, a float judged by its text
def finite [v: any]: nothing -> bool {
    match ($v | describe) {
        "int" => true,
        "float" => (($v | into string) not-in ["inf" "-inf" "NaN"]),
        _ => false,
    }
}

# The declared matrix held to its model and to itself
export def matrix-of [file: path]: nothing -> record<matrix: any, problems: list<string>> {
    let m = (open $file)
    let shape = (nutype problems $m (open --raw $MODEL | decode utf-8) $MODEL)
    if not ($shape | is-empty) { return { matrix: $m, problems: $shape } }
    let hosts = ($m.hosts | get host)
    let own = ($m.batteries | each {|b|
        let names = ($b.conditions | get name)
        let stray = ($b.batches | where {|n| $n not-in $names } | each {|n| $"($b.host)'s ($b.battery) runs a batch of ($n), no condition of it" })
        let counts = ($names | each {|n|
            let c = (($b.batches | where {|x| $x == $n } | length) * $b.runs)
            if $c != $b.per_condition { $"($b.host)'s ($b.battery) runs ($n) ($c) times, not ($b.per_condition)" }
        } | compact)
        let seeds = (if ($b.seeds | length) != ($b.batches | length) {
            [$"($b.host)'s ($b.battery) declares ($b.seeds | length) seed lists for ($b.batches | length) batches"]
        } else {
            $b.seeds | enumerate | where {|s| ($s.item | length) != $b.runs } | each {|s| $"($b.host)'s ($b.battery) declares ($s.item | length) seeds for batch ($s.index + 1)'s ($b.runs) runs" }
        })
        let host = (if $b.host not-in $hosts { [$"($b.battery) runs on ($b.host), a host the matrix does not declare"] } else { [] })
        $stray ++ $counts ++ $seeds ++ $host
    } | flatten)
    let deciding = ($m.hosts | each {|h| $h.deciding | values | where {|v| ($m.batteries | where {|b| $b.host == $h.host and $b.battery == $v } | is-empty) } | each {|v| $"($h.host) decides by ($v), no battery of its own" } } | flatten)
    let source = ($m.batteries | where {|b| $b.host == $m.calibration.host and $b.battery == $m.calibration.battery })
    let cal = (if ($source | is-empty) { [$"the calibration reads ($m.calibration.host)'s ($m.calibration.battery), no battery"] } else { [] })
    { matrix: $m, problems: ($own ++ $deciding ++ $cal) }
}

# Every declared condition on each target of its host, with its slots
def conditions-of [m: record]: nothing -> list<any> {
    $m.batteries | each {|b|
        let targets = ($m.hosts | where host == $b.host | get 0.targets)
        $b.conditions | each {|c|
            let slots = ($b.batches | enumerate | where item == $c.name | each {|e| 0..<$b.runs | each {|j| { position: ($e.index * $b.runs + $j + 1), seed: ($b.seeds | get $e.index | get $j) } } } | flatten)
            $targets | each {|t| $c | merge { host: $b.host, battery: $b.battery, workload: $b.workload, backend: $b.backend, target: $t, slots: $slots, key: $"($b.host)/($t)/($b.battery)/($c.name)" } }
        } | flatten
    } | flatten
}

# The declared condition a run's fields name, or null
def condition-of [conds: list<any>, r: record]: nothing -> any {
    $conds | where {|c| $MATCH | all {|k| ($c | get $k) == ($r | get -o $k) } } | get -o 0
}

# The figures a run of its condition lacks, each by name, every one finite
def figure-problems [r: record, c: record, legs: list<string>]: nothing -> list<string> {
    let k = (if (finite ($r | get -o k_violations)) { [] } else { ["k_violations"] })
    if $c.workload == "fps" {
        let legged = ($legs | each {|l|
            let row = ($r | get -o legs | default [] | where {|x| ($x | get -o leg) == $l } | get -o 0)
            ["critical_median_ms" "presented_p95_ms"] | where {|f| $row == null or not (finite ($row | get -o $f)) } | each {|f| $"($l)'s ($f)" }
        } | flatten)
        let whole = (["submission_age_median_ms" "late_wakes" "catch_ups"] ++ (if $c.probed { ["shown_p95_ms"] } else { [] }) | where {|f| not (finite ($r | get -o $f)) })
        $k ++ $legged ++ $whole
    } else {
        let whole = (["presented_median_ms" "presented_p95_ms"] ++ (if $c.timing { ["d_median_ms"] } else { [] }) | where {|f| not (finite ($r | get -o $f)) })
        let phases = (if $c.timing and ($r | get -o phases) == null { ["phases"] } else { [] })
        $k ++ $whole ++ $phases
    }
}

# A kept run's wake delays over its qualifying frames, s less T in ticks, its
# capture complete and valid and its receipt stage passed
def wake-delays [dir: string]: nothing -> list<int> {
    let read = (gauge identity corrected ($dir | path join "identity.nuon"))
    let legs = (gauge report legs-for $dir $read.identity "" | get legs)
    let m = (gauge measure (open --raw ($dir | path join "api.out") | into binary) $legs --cap ($read.identity | get -o cap | default 60))
    if not ($m.complete and $m.valid and $m.acceptance.available) {
        let why = (if not $m.complete { $"incomplete: ($m.problems | first 3 | str join '; ')" } else if not $m.valid { $"invalid: ($m.invalid | first 3 | str join '; ')" } else { $"its receipts unread: ($m.acceptance.reason)" })
        error make { msg: $why }
    }
    gauge measure wake-delays $m.rows
}

# The q-th quantile of values by nearest rank
def nearest-rank [values: list<int>, q: float]: nothing -> int {
    let s = ($values | sort)
    let k = ((($q * ($s | length)) | math ceil) - 1)
    $s | get ([$k 0] | math max)
}

# eps by the plan's rule over runs on the targets, each run's capture read anew
def calibration-figures [targets: list<string>, runs: list<any>]: nothing -> record {
    let per = ($targets | each {|t|
        let these = ($runs | where {|r| $r.target == $t })
        let read = ($these | each {|r| try { { delays: (wake-delays $r.dir), problem: null } } catch {|e| { delays: [], problem: $"run ($r.id)'s capture unread: ($e.msg)" } } })
        let delays = ($read | each {|x| $x.delays } | flatten)
        {
            target: $t
            runs: ($these | length)
            qualifying: ($delays | length)
            p999: (if ($delays | is-empty) { null } else { nearest-rank $delays 0.999 })
            past_cap: ($delays | where {|d| $d > $EPS_CAP } | length)
            problems: ($read | each {|x| $x.problem } | compact)
        }
    })
    let short = ($per | any {|x| $x.qualifying < $N_CAL })
    let top = ($per | each {|x| $x.p999 } | compact | append 0 | math max)
    let rounded = ([(($top / $EPS_QUANTUM | math ceil) * $EPS_QUANTUM) $EPS_QUANTUM] | math max)
    let state = (if $short { "short" } else if $top > $EPS_CAP { "capped" } else { "calibrated" })
    let eps = (if $state == "capped" { $EPS_CAP } else if $state == "calibrated" { $rounded } else { null })
    { state: $state, eps: $eps, targets: $per }
}

# eps recomputed from the calibration's source conditions' runs, complete on every target
def calibration-of [m: record, conds: list<any>, runs: list<any>, complete: list<string>]: nothing -> record {
    let src = $m.calibration
    let targets = ($m.hosts | where host == $src.host | get 0.targets)
    let sources = ($conds | where {|c| $c.host == $src.host and $c.battery == $src.battery and $c.kernel == $src.kernel })
    let figures = (calibration-figures $targets ($runs | where {|r| $r.key in ($sources | get key) }))
    let held = ($targets | each {|t|
        let keys = ($sources | where target == $t | get key)
        { target: $t, complete: ((not ($keys | is-empty)) and ($keys | all {|k| $k in $complete })) }
    })
    {
        state: $figures.state
        eps: $figures.eps
        complete: ($held | all {|x| $x.complete })
        targets: ($figures.targets | each {|x| $x | insert complete ($held | where target == $x.target | get 0.complete) })
    }
}

# eps from a calibration capture's runs, each run's target its identity's spec, written as calibration.nuon
export def calibrate [base: path, out: path] {
    let selector = (identity reader [$STRESS $JAB])
    let mx = (matrix-of $MATRIX)
    if not ($mx.problems | is-empty) { error make { msg: $"($MATRIX): ($mx.problems | str join '; ')" } }
    let targets = ($mx.matrix.hosts | where host == $mx.matrix.calibration.host | get 0.targets)
    let base = ($base | path expand)
    let runs = (open ($base | path join "batches.nuon") | each {|b|
        glob ($base | path join $b.label "run_*") | where {|d| ($d | path type) == "dir" } | sort | each {|d|
            let id = (gauge identity corrected ($d | path join "identity.nuon")).identity
            { id: $"($b.label)/($d | path basename)", dir: $d, target: ($id | get -o machine.spec.name) }
        }
    } | flatten)
    let foreign = ($runs | where {|r| $r.target not-in $targets })
    if not ($foreign | is-empty) { error make { msg: $"runs on no target the matrix declares: ($foreign | each {|r| $'($r.id) on ($r.target | to nuon)' } | str join ', ')" } }
    let c = (calibration-figures $targets $runs)
    let record = {
        state: $c.state
        eps: $c.eps
        qualifying: ($c.targets | reduce --fold {} {|x, acc| $acc | insert $x.target $x.qualifying })
        targets: $c.targets
        base: $base
        runs: $runs
        selector: $selector
    }
    mkdir $out
    $record | to nuon --indent 1 | save --raw -f ($out | path join "calibration.nuon")
    print $"timing calibrate: ($c.state), eps ($c.eps | to nuon) ticks"
    for t in $c.targets { print $"  ($t.target): ($t.runs) runs, ($t.qualifying) qualifying frames, 99.9th ($t.p999 | to nuon) ticks, ($t.past_cap) past the cap(if ($t.problems | is-empty) { '' } else { $'; ($t.problems | str join "; ")' })" }
}

# The declared calibration held to the plan and to its recomputation
def calibration-problems [declared: any, recomputed: record]: nothing -> list<string> {
    if not (($declared | describe) | str starts-with "record") { return ["the readings declare no calibration"] }
    let state = ($declared | get -o state)
    if $state not-in $STATES { return [$"the calibration's state ($state | to nuon), none of ($STATES | str join ', ')"] }
    let eps = ($declared | get -o eps)
    let bounds = (if $state == "short" { [] } else if not (finite $eps) or ($eps mod $EPS_QUANTUM) != 0 or $eps < $EPS_QUANTUM or $eps > $EPS_CAP { [$"eps ($eps | to nuon), not a multiple of ($EPS_QUANTUM) ticks from ($EPS_QUANTUM) to ($EPS_CAP)"] } else { [] })
    let counts = ($recomputed.targets | each {|x|
        let said = ($declared | get -o qualifying | default {} | get -o $x.target)
        if $said != $x.qualifying { $"the calibration says ($said | to nuon) qualifying frames on ($x.target), its frames hold ($x.qualifying)" }
    } | compact)
    let same = (if $state != $recomputed.state or ($state != "short" and $eps != $recomputed.eps) { [$"the calibration says ($state) at eps ($eps | to nuon), its frames ($recomputed.state) at eps ($recomputed.eps | to nuon)"] } else { [] })
    $bounds ++ $counts ++ $same
}

# A control bound to the runs of the two conditions apart by its flag alone
def control-binding [c: record, placed: list<any>, conds: list<any>, complete: list<string>]: nothing -> record {
    let flag = (if ($c | get -o kind) == "shim" { "probed" } else if ($c | get -o kind) == "timing" { "timing" } else { null })
    let named = $"the ($c | get -o kind) control of ($c | get -o host) on ($c | get -o target)"
    if $flag == null { return { pair: null, problems: [$"($named): a kind neither shim nor timing"] } }
    let ids = ($c | get -o runs | default [])
    let mine = ($placed | where {|r| $r.id in $ids and $r.key != null })
    let found = ($mine | each {|r| $r.id })
    let unknown = ($ids | where {|i| $i not-in $found } | each {|i| $"($named) names ($i), no run of a declared condition" })
    let keys = ($mine | each {|r| $r.key } | uniq)
    let two = ($conds | where {|x| $x.key in $keys })
    let others = ($MATCH | where {|k| $k != $flag })
    let paired = ((($two | length) == 2) and ($others | all {|k| ($two | each {|x| $x | get $k } | uniq | length) == 1 }) and (($two | each {|x| $x | get $flag } | uniq | length) == 2))
    if not ($unknown | is-empty) { return { pair: null, problems: $unknown } }
    if not $paired { return { pair: null, problems: [$"($named) names no two conditions apart by ($flag) alone"] } }
    let all = ($placed | where {|r| $r.key in $keys } | each {|r| $r.id } | sort)
    if $all != ($ids | uniq | sort) { return { pair: null, problems: [$"($named) names not exactly its two conditions' runs"] } }
    let on = ($two | where {|x| $x | get $flag } | first)
    let off = ($two | where {|x| not ($x | get $flag) } | first)
    { pair: { kind: $c.kind, host: $on.host, target: $on.target, on: $on.key, off: $off.key, passing: (($c | get -o passing) == true), complete: ($keys | all {|k| $k in $complete }) }, problems: [] }
}

# A host limit bound to the display battery's probed runs of both kernels
def limit-binding [l: record, placed: list<any>, conds: list<any>, m: record, pairs: list<any>]: nothing -> record {
    let named = $"the host limit of ($l | get -o host) on ($l | get -o target)"
    let h = ($m.hosts | where host == ($l | get -o host) | get -o 0)
    if $h == null { return { limit: null, problems: [$"($named): a host the matrix does not declare"] } }
    let probed = ($conds | where {|c| $c.host == $h.host and $c.target == ($l | get -o target) and $c.battery == $h.deciding.display and $c.probed })
    let keys = ($probed | each {|c| $c.key })
    let all = ($placed | where {|r| $r.key in $keys } | each {|r| $r.id } | sort)
    if ($keys | length) != 2 or $all != ($l | get -o runs | default [] | uniq | sort) { return { limit: null, problems: [$"($named) names not exactly the probed runs of both kernels"] } }
    let admitted = ($keys | all {|k| $pairs | any {|p| $p.kind == "shim" and $p.on == $k and $p.passing and $p.complete } })
    let claims = (($l | get -o admissible) == true)
    if $claims and not $admitted { return { limit: null, problems: [$"($named) claims admissible runs whose shim controls are not both admitted"] } }
    { limit: { host: $h.host, target: $l.target, admissible: $claims, limit: ($l | get -o limit) }, problems: [] }
}

# Each run with its declared condition's key, or why it is at no declared slot
def placed-of [conds: list<any>, runs: list<any>]: nothing -> list<any> {
    $runs | each {|r|
        let c = (condition-of $conds $r)
        if $c == null { $r | upsert key null | upsert why "matches no declared condition" } else {
            let slot = ($c.slots | where {|s| $s.position == ($r | get -o position) and $s.seed == ($r | get -o seed) })
            $r | upsert key $c.key | upsert why (if ($slot | is-empty) { $"of ($c.key) at position ($r | get -o position | to nuon) and seed ($r | get -o seed | to nuon), no declared slot" } else { null })
        }
    }
}

# The readings held to the matrix before any rule: refusals and the short
export def validate [readings: record, m: record]: nothing -> record {
    let conds = (conditions-of $m)
    let runs = ($readings | get -o runs | default [])
    let placed = (placed-of $conds $runs)
    let strays = ($placed | where {|r| $r.why != null } | each {|r| $"run ($r | get -o id): ($r.why)" })
    let twice = (["id" "dir" "nonce"] | each {|f| $runs | each {|r| $r | get -o $f } | compact | uniq --count | where count > 1 | each {|x| $"($f) ($x.value) on ($x.count) runs" } } | flatten)
    let seated = ($placed | where {|r| $r.why == null })
    let doubled = ($seated | group-by {|r| $"($r.key) ($r.position)" } | items {|k, v| if ($v | length) > 1 { $"($k) filled ($v | length) times" } } | compact)

    # the freeze: every run's image and kernel its condition's declared export
    let freeze = ($readings | get -o freeze | default {})
    let roles = {|kind: string, role: string| $freeze | get -o $kind | default [] | where {|x| ($x | get -o role) == $role } | get -o 0.sha256 }
    let unnamed = ($conds | each {|c| [[images $c.image] [kernels $c.kernel]] | each {|p| if (do $roles $p.0 $p.1) == null { $"the freeze names no ($p.0 | str substring 0..-2) of role ($p.1)" } } | compact } | flatten | uniq)
    let foreign_build = ($seated | where {|r|
        let c = ($conds | where key == $r.key | first)
        ($r | get -o image_sha256) != (do $roles images $c.image) or ($r | get -o kernel_sha256) != (do $roles kernels $c.kernel)
    })
    let mixed = ($foreign_build | each {|r| $"run ($r.id) of ($r.key) is not its condition's frozen export" })

    # each condition's slots filled once by valid runs holding every figure
    let short = ($conds | each {|c|
        let these = ($seated | where key == $c.key)
        let missing = ($c.slots | where {|s| ($these | where {|r| $r.position == $s.position } | is-empty) })
        let invalid = ($these | where {|r| ($r | get -o valid) != true } | each {|r| $"($c.key): run ($r.id) invalid: ($r | get -o invalid | default [] | str join '; ')" })
        let figures = ($these | where {|r| ($r | get -o valid) == true } | each {|r|
            let lacking = (figure-problems $r $c $m.legs)
            if not ($lacking | is-empty) { $"($c.key): run ($r.id) lacks ($lacking | str join ', ')" }
        } | compact)
        let absent = (if ($missing | is-empty) { [] } else { [$"($c.key): ($missing | length) of its ($c.slots | length) runs absent"] })
        { key: $c.key, problems: ($absent ++ $invalid ++ $figures) }
    })
    let refused_keys = ($foreign_build | each {|r| $r.key } | uniq)
    let complete = ($short | where {|x| ($x.problems | is-empty) and $x.key not-in $refused_keys } | each {|x| $x.key })
    let good = ($seated | where {|r| $r.key in $complete })

    # the controls and the host limits, each bound to its runs
    let bound = ($readings | get -o controls | default [] | each {|c| control-binding $c $placed $conds $complete })
    let pairs = ($bound | each {|b| $b.pair } | compact)
    let limited = ($readings | get -o host_limits | default [] | each {|l| limit-binding $l $placed $conds $m $pairs })

    # the calibration, recomputed from its own runs' captures
    let recomputed = (calibration-of $m $conds $good $complete)
    let declared = ($readings | get -o calibration)
    let cal_refused = (if $recomputed.complete { calibration-problems $declared $recomputed } else if not (($declared | describe) | str starts-with "record") or ($declared | get -o state) not-in $STATES { ["the calibration's state is none of the plan's"] } else { [] })
    let cal_short = (if $recomputed.complete { $recomputed.targets | each {|x| $x.problems } | flatten } else { [$"the calibration's runs, ($m.calibration.host)'s ($m.calibration.battery) ($m.calibration.kernel), incomplete"] })

    let refused = ($strays ++ $twice ++ $doubled ++ $unnamed ++ $mixed ++ ($bound | each {|b| $b.problems } | flatten) ++ ($limited | each {|l| $l.problems } | flatten) ++ $cal_refused)
    {
        conditions: $conds
        runs: $good
        complete: $complete
        refused: $refused
        insufficient: (($short | each {|x| $x.problems } | flatten) ++ $cal_short)
        controls: $pairs
        limits: ($limited | each {|l| $l.limit } | compact)
        calibration: $recomputed
    }
}

# An arm's figure for a statistic, its range, and its count
def figure-of [runs: list<any>, stat: closure]: nothing -> record {
    let values = ($runs | each {|r| do $stat $r } | where {|v| $v != null })
    if ($values | is-empty) { return { figure: null, range: null, count: 0 } }
    { figure: ($values | math median), range: (($values | math max) - ($values | math min)), count: ($values | length) }
}

# Two arms compared on a statistic: figures, d, and N
def compare [base: list<any>, compared: list<any>, stat: closure]: nothing -> record {
    let b = (figure-of $base $stat)
    let c = (figure-of $compared $stat)
    if $b.figure == null or $c.figure == null { return { base: $b.figure, compared: $c.figure, d: null, n: null, runs: [$b.count $c.count] } }
    { base: $b.figure, compared: $c.figure, d: ($c.figure - $b.figure), n: (([$b.range $c.range] | math max) / 2.0), runs: [$b.count $c.count] }
}

# A complete condition's runs by its fields, or null where none is complete
def arm [v: record, cond: record]: nothing -> any {
    let c = ($v.conditions | where {|x| $cond | items {|k, val| ($x | get -o $k) == $val } | all {|y| $y } } | get -o 0)
    if $c == null or $c.key not-in $v.complete { return null }
    $v.runs | where key == $c.key
}

# A leg's statistic of a run, null where the run has no such leg
def leg-stat [r: record, leg: string, field: string]: nothing -> any {
    $r | get -o legs | default [] | where {|l| $l.leg == $leg } | get -o 0 | default {} | get -o $field
}

# A landed run restored once for the decision: its tree, or why it is not
def restoration-of [run: string, scratch: path]: nothing -> record<run: string, tree: any, why: string> {
    let dir = ($scratch | path join ($run | path basename))
    try {
        landing restore $run $dir | ignore
        { run: $run, tree: ($dir | path join "tree"), why: "" }
    } catch {|e| { run: $run, tree: null, why: $e.msg } }
}

# A check read from its landed run's restored step: demonstrated, failed, or unproven
def check-state [c: any, name: string, restored: list<any>]: nothing -> record<check: string, state: string, why: string> {
    let unproven = {|why: string| { check: $name, state: "unproven", why: $why } }
    if $c == null { return (do $unproven "no landed run bound") }
    let manifest = ($c.run | path join "run.nuon")
    if not ($manifest | path exists) { return (do $unproven $"($c.run) holds no run.nuon") }
    if (open --raw $manifest | hash sha256) != ($c | get -o run_sha256) { return (do $unproven $"($c.run)'s run.nuon is not the one the readings bound") }
    let r = ($restored | where run == $c.run | first)
    if $r.tree == null { return (do $unproven $"($c.run) not restored: ($r.why)") }
    let step_file = ($r.tree | path join $c.step "step.nuon")
    let out_file = ($r.tree | path join $c.step "run.stdout")
    if not (($step_file | path exists) and ($out_file | path exists)) { return (do $unproven $"($c.step) holds no step.nuon and run.stdout") }
    let step = (try { open --raw $step_file | decode | from nuon } catch { null })
    if $step == null { return (do $unproven $"($c.step)'s step.nuon unreadable") }
    let p2 = (("P2" in ($step | get -o symbols | default [])) and ($step | get -o kernel.held) == true and ($step | get -o kernel_source.equal) == true)
    if not $p2 { return (do $unproven $"($c.step) is no P2 build held to its symbols on the comparison's kernel source") }
    if ($step | get -o exit) != 0 or ($step | get -o ok) != true { return { check: $name, state: "failed", why: $"($c.step) exited ($step | get -o exit | to nuon), its assertions failing" } }
    let passed = (open --raw $out_file | decode | lines | any {|l| $l =~ '^\S+: ok$' })
    if not $passed { return (do $unproven $"($c.step)'s output holds no line of its program passing") }
    { check: $name, state: "demonstrated", why: "" }
}

# A declared P2 slot's K on its frozen kernel: 0 demonstrated, past it failed
def slot-state [key: string, position: int, r: any, p2: any]: nothing -> record<key: string, position: int, run: any, state: string, k: any, why: string> {
    let at = { key: $key, position: $position, run: ($r | get -o id) }
    let k = ($r | get -o k_violations)
    let state = {|s: string, why: string| $at | merge { state: $s, k: $k, why: $why } }
    if $r == null { return (do $state "unproven" "its run missing") }
    let contract = ($r | get -o contract)
    if $contract == null or ($contract | get -o available) != true { return (do $state "unproven" $"its contract unavailable: ($contract | get -o reason | default 'none recorded')") }
    let sha = ($r | get -o kernel_sha256)
    if $sha == null { return (do $state "unproven" "its kernel unattributed, no hash recorded") }
    if $p2 == null or $sha != $p2 { return (do $state "unproven" "its kernel unattributed, another export's") }
    if not (finite $k) { return (do $state "unproven" "its K unread") }
    if $k > 0 { return (do $state "failed" $"K violated ($k) times") }
    do $state "demonstrated" ""
}

# P2's eligibility, demonstrated, failed, or unproven: its checks read from
# their landed runs, K from every P2 slot and run on the frozen P2 kernel
def eligibility [readings: record, m: record, scratch: path]: nothing -> record<state: string, checks: list<any>, runs: list<any>, why: list<string>> {
    let given = ($readings | get -o checks)
    let bound = (if (($given | describe) | str starts-with "table") or (($given | describe) | str starts-with "list") { $given } else { [] })
    let restored = ($bound | each {|c| $c | get -o run } | compact | uniq | each {|r| restoration-of $r $scratch })
    let checks = ($CHECKS | each {|name| check-state ($bound | where {|c| ($c | get -o check) == $name } | get -o 0) $name $restored })
    let p2 = ($readings | get -o freeze.kernels | default [] | where {|x| ($x | get -o role) == "P2" } | get -o 0.sha256)
    let conds = (conditions-of $m)
    let runs = ($readings | get -o runs | default [])
    let placed = (placed-of $conds $runs)
    let slots = ($conds | where kernel == "P2" | each {|c| $c.slots | each {|s|
        slot-state $c.key $s.position ($placed | where {|r| $r.key == $c.key and ($r | get -o position) == $s.position } | get -o 0) $p2
    } } | flatten)
    let observed = ($runs | where {|r| $p2 != null and ($r | get -o kernel_sha256) == $p2 and ($r | get -o contract.available) == true and (finite ($r | get -o k_violations)) and $r.k_violations > 0 } | each {|r| $"K violated ($r.k_violations) times in ($r.id) on P2's kernel" })
    let failed = (($checks | any {|c| $c.state == "failed" }) or ($slots | any {|s| $s.state == "failed" }) or ($observed | is-not-empty))
    let unproven = (($checks | any {|c| $c.state == "unproven" }) or ($slots | any {|s| $s.state == "unproven" }))
    let why = (($checks | where state != "demonstrated" | each {|c| $"P2's ($c.check) ($c.state): ($c.why)" }) ++ ($slots | where state != "demonstrated" | each {|s| $"($s.key) at ($s.position) ($s.state): ($s.why)" }) ++ $observed | uniq)
    { state: (if $failed { "failed" } else if $unproven { "unproven" } else { "demonstrated" }), checks: $checks, runs: $slots, why: $why }
}

# The regression rule on each declared host's deciding game runs
def regression [v: record, m: record]: nothing -> list<any> {
    $m.hosts | each {|h| $h.targets | each {|t|
        let base = (arm $v { host: $h.host, target: $t, battery: $h.deciding.guest, workload: "fps", kernel: "P0", probed: false })
        let comp = (arm $v { host: $h.host, target: $t, battery: $h.deciding.guest, workload: "fps", kernel: "P2", probed: false })
        if $base == null or $comp == null { return [{ host: $h.host, target: $t, leg: null, state: "insufficient", base: null, compared: null, d: null, n: null, runs: null, regressing: false }] }
        $m.legs | each {|leg|
            let c = (compare $base $comp {|r| leg-stat $r $leg "critical_median_ms" })
            $c | merge { host: $h.host, target: $t, leg: $leg, state: "admissible", regressing: ($c.d > $c.n and $c.d > $REGRESSION_FLOOR_MS) }
        }
    } | flatten } | flatten
}

# The guest's presentation on each declared host's deciding game runs
def presentation-guest [v: record, m: record]: nothing -> list<any> {
    $m.hosts | each {|h| $h.targets | each {|t|
        let base = (arm $v { host: $h.host, target: $t, battery: $h.deciding.guest, workload: "fps", kernel: "P0", probed: false })
        let comp = (arm $v { host: $h.host, target: $t, battery: $h.deciding.guest, workload: "fps", kernel: "P2", probed: false })
        if $base == null or $comp == null { return [{ host: $h.host, target: $t, leg: null, state: "insufficient", base: null, compared: null, d: null, n: null, runs: null, worse: false }] }
        $LATE_LEGS | each {|leg|
            let c = (compare $base $comp {|r| leg-stat $r $leg "presented_p95_ms" })
            $c | merge { host: $h.host, target: $t, leg: $leg, state: "admissible", worse: ($c.compared > ($c.base + $c.n)) }
        }
    } | flatten } | flatten
}

# Each declared host's display side on each target, from its probed runs
def presentation-display [v: record, m: record]: nothing -> list<any> {
    $m.hosts | each {|h| $h.targets | each {|t|
        let d = $h.deciding.display
        let row = { host: $h.host, target: $t, base: null, compared: null, d: null, n: null, worse: false }
        let probed = ($v.conditions | where {|c| $c.host == $h.host and $c.target == $t and $c.battery == $d and $c.probed })
        if ($probed | is-empty) { return ($row | merge { state: "blocked", why: "no probed condition declared" }) }
        let base = (arm $v { host: $h.host, target: $t, battery: $d, workload: "fps", kernel: "P0", probed: true })
        let comp = (arm $v { host: $h.host, target: $t, battery: $d, workload: "fps", kernel: "P2", probed: true })
        if $base == null or $comp == null { return ($row | merge { state: "insufficient", why: "a probed condition incomplete" }) }
        let limits = ($v.limits | where {|l| $l.host == $h.host and $l.target == $t })
        let shim = ([($base | first | get key) ($comp | first | get key)] | all {|k| $v.controls | any {|p| $p.kind == "shim" and $p.on == $k and $p.passing and $p.complete } })
        if ($limits | any {|l| $l.admissible }) {
            $row | merge { state: "out", why: "a host limit on admissible runs: the decision guest-side" }
        } else if $shim {
            let c = (compare $base $comp {|r| $r.shown_p95_ms })
            $row | merge $c | merge { state: "admissible", why: "", worse: ($c.compared > ($c.base + $c.n)) }
        } else if not ($limits | is-empty) {
            $row | merge { state: "insufficient", why: "a host limit claimed on inadmissible runs" }
        } else {
            $row | merge { state: "insufficient", why: "no admitted passing shim control for each rule's readings" }
        }
    } } | flatten
}

# The second workload's gate on each declared host and target, by the strategy
def walk-gate [v: record, m: record, strategy: string]: nothing -> list<any> {
    $m.hosts | each {|h| $h.targets | each {|t|
        let w = $h.deciding.walk
        let row = { host: $h.host, target: $t, order: (if $strategy == "reordered" { "prepare" } else { "await" }), median: null, p95: null, fails: false }
        let base = (arm $v { host: $h.host, target: $t, battery: $w, workload: "walk", kernel: "P0", order: "await", timing: false })
        if $strategy == "reordered" {
            let comp = (arm $v { host: $h.host, target: $t, battery: $w, workload: "walk", kernel: "P2", order: "prepare", timing: false })
            if $base == null or $comp == null { return ($row | merge { state: "insufficient", why: "a TIMING-off arm the strategy reads incomplete" }) }
            let median = (compare $base $comp {|r| $r.presented_median_ms })
            let p95 = (compare $base $comp {|r| $r.presented_p95_ms })
            $row | merge { state: "admissible", why: "", median: $median, p95: $p95, fails: (($median.compared > ($median.base + $median.n)) or ($p95.compared > ($p95.base + $p95.n))) }
        } else {
            let on = (arm $v { host: $h.host, target: $t, battery: $w, workload: "walk", kernel: "P2", order: "await", timing: true })
            if $base == null or $on == null { return ($row | merge { state: "insufficient", why: "an arm the tradeoff reports incomplete" }) }
            let median = (compare $base $on {|r| $r.presented_median_ms })
            let p95 = (compare $base $on {|r| $r.presented_p95_ms })
            $row | merge { state: "reported", why: "P2 await's TIMING-on figures, held to nothing", median: $median, p95: $p95 }
        }
    } } | flatten
}

# Each TIMING-on walk arm's D and phases, admissible or instrumented
def walk-phases [v: record, m: record]: nothing -> list<any> {
    $m.hosts | each {|h| $h.targets | each {|t|
        $v.conditions | where {|c| $c.host == $h.host and $c.target == $t and $c.battery == $h.deciding.walk and $c.timing } | each {|c|
            let runs = (if $c.key in $v.complete { $v.runs | where key == $c.key } else { [] })
            let d = (if ($runs | is-empty) { null } else { figure-of $runs {|r| $r.d_median_ms } | get figure })
            let control = ($v.controls | any {|p| $p.kind == "timing" and $p.on == $c.key and $p.passing and $p.complete })
            { host: $h.host, target: $t, kernel: $c.kernel, order: $c.order, d_ms: $d, evidence: (if ($runs | is-empty) { "insufficient" } else if $control { "admissible" } else { "instrumented-only" }) }
        }
    } | flatten } | flatten
}

# The noise gate over every deciding comparison of these hosts
def noise-gate [hosts: list<string>, regressions: list<any>, guest: list<any>, display: list<any>, walk: list<any>]: nothing -> record {
    let critical = ($regressions | where {|r| $r.host in $hosts and $r.n != null } | each {|r| { what: $"critical path, ($r.leg)", host: $r.host, target: $r.target, n: $r.n } })
    let presented = ($guest | where {|r| $r.host in $hosts and $r.n != null } | each {|r| { what: $"presented 95th, ($r.leg)", host: $r.host, target: $r.target, n: $r.n } })
    let shown = ($display | where {|r| $r.host in $hosts and $r.state == "admissible" and $r.n != null } | each {|r| { what: "shown 95th", host: $r.host, target: $r.target, n: $r.n } })
    let walked = ($walk | where {|r| $r.host in $hosts and $r.state == "admissible" } | each {|r| [{ what: "walk median", host: $r.host, target: $r.target, n: $r.median.n } { what: "walk 95th", host: $r.host, target: $r.target, n: $r.p95.n }] } | flatten)
    let over = ($critical ++ $presented ++ $shown ++ $walked | where {|r| $r.n > $NOISE_GATE_MS })
    { passed: ($over | is-empty), over: $over }
}

# The outcome over these hosts' rows, in the plan's order
def outcome-of [hosts: list<string>, eligible: record, refused: bool, calibrated: bool, rows: record]: nothing -> record {
    let regress = ($rows.regression | where {|r| $r.host in $hosts })
    let guest = ($rows.guest | where {|r| $r.host in $hosts })
    let display = ($rows.display | where {|r| $r.host in $hosts })
    let walk = ($rows.walk | where {|r| $r.host in $hosts })
    let noise = (noise-gate $hosts $regress $guest $display $walk)
    let short = (($regress ++ $guest | any {|r| $r.state == "insufficient" }) or ($display | any {|r| $r.state in ["insufficient" "blocked"] }) or ($walk | any {|r| $r.state == "insufficient" }))
    let insufficient = ((not $calibrated) or (not $noise.passed) or $short)
    let regressing = (($regress | any {|r| $r.regressing }) or ($guest | any {|r| $r.worse }) or ($display | any {|r| $r.worse }))
    let walk_failed = ($walk | any {|r| $r.fails })
    let outcome = (if $eligible.state == "failed" { "ineligible" } else if $refused { "refused" } else if $insufficient or $eligible.state != "demonstrated" { "insufficient" } else if $regressing { "regressing" } else if $walk_failed { "walk_failed" } else { "chosen" })
    { outcome: $outcome, noise: $noise }
}

# The decision over a readings record and the matrix, validated before any rule
export def decide [readings: record, m: record, scratch: path]: nothing -> record {
    let v = (validate $readings $m)
    let eligible = (eligibility $readings $m $scratch)
    let strategy = ($readings | get -o strategy)
    let rows = {
        regression: (regression $v $m)
        guest: (presentation-guest $v $m)
        display: (presentation-display $v $m)
        walk: (walk-gate $v $m $strategy)
    }
    let phases = (walk-phases $v $m)
    let refused = (not ($v.refused | is-empty))
    let calibrated = ($v.calibration.complete and $v.calibration.state != "short")
    let hosts = ($m.hosts | get host)
    let all = (outcome-of $hosts $eligible $refused $calibrated $rows)
    let box = (outcome-of ["box"] $eligible $refused $calibrated $rows)
    let scope = (if $all.outcome != "chosen" { null } else if $hosts == ["box"] { "provisional" } else { "host-backed" })
    {
        strategy: $strategy
        hosts: $hosts
        validation: { refused: $v.refused, insufficient: $v.insufficient, complete: $v.complete, controls: $v.controls, limits: $v.limits }
        calibration: { declared: ($readings | get -o calibration), recomputed: $v.calibration, calibrated: $calibrated }
        eligibility: $eligible
        regression: $rows.regression
        presentation: { guest: $rows.guest, display: $rows.display }
        walk: { gate: $rows.walk, phases: $phases }
        noise: $all.noise
        blockers: ($rows.display | where state == "blocked" | each {|r| $"($r.host) on ($r.target): ($r.why)" })
        outcome: $all.outcome
        scope: $scope
        box: { outcome: $box.outcome, standing: (if $box.outcome == "chosen" { "provisional" } else { null }) }
        contract: (if $all.outcome == "chosen" { "met" } else { "unmet" })
    }
}

# The decision over one readings record, written as decision.nuon
export def main [readings: path, out: path] {
    let selector = (identity reader [$STRESS $JAB])
    let mx = (matrix-of $MATRIX)
    if not ($mx.problems | is-empty) { error make { msg: $"($MATRIX): ($mx.problems | str join '; ')" } }
    let raw = (open --raw $readings | into binary)
    mkdir $out
    let decision = (decide ($raw | decode | from nuon) $mx.matrix ($out | path join "checks") | merge { readings_sha256: ($raw | hash sha256), matrix_sha256: (open --raw $MATRIX | hash sha256), selector: $selector })
    $decision | to nuon --indent 1 | save --raw -f ($out | path join "decision.nuon")
    print $"timing select: ($decision.outcome)(if $decision.scope == null { '' } else { ', ' + $decision.scope }), the contract ($decision.contract)"
    print $"  eligibility: ($decision.eligibility.state)"
    for p in $decision.eligibility.why { print $"  eligibility: ($p)" }
    for p in $decision.validation.refused { print $"  refused: ($p)" }
    for p in $decision.validation.insufficient { print $"  short: ($p)" }
    for b in $decision.blockers { print $"  blocker: ($b)" }
}
