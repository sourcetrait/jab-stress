use (path self ../../../../../../jab/nu/mod/identity)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../fierce/proberuns)
use (path self ../../../fierce/observer)
use (path self ../../walk/reading)
use (path self ../../walk/stream)

# The workbench, the checkout the assembler's identity names
const STRESS = (path self ../../../../.. | path expand)

# jab beside it, whose gauge and stream modules read every run
const JAB = (path self ../../../../../../jab | path expand)

# The kernel's tick, the period at the cap of 60 in the guest clock's ticks
const PERIOD = 166666

# The guest clock's ticks a microsecond
const US_TICKS = 10

# The bytes of walk's stream header
const WALK_HEADER = 80

# Microseconds as milliseconds, null kept
def ms [us: any]: nothing -> any {
    if $us == null { null } else { $us / 1000.0 }
}

# A list's nearest-rank quantile, null for no values
def rank [values: list<number>, q: float]: nothing -> any {
    let n = ($values | length)
    if $n == 0 { return null }
    $values | sort | get ([((($n * $q) | math ceil | into int) - 1) 0] | math max)
}

# A flag's value in a batch's words, refused when the words name none
def word-of [words: list<string>, flag: string, label: string]: nothing -> string {
    let v = ($words | window 2 | where {|w| $w.0 == $flag } | get -o 0.1)
    if $v == null { error make { msg: $"batch ($label)'s words name no ($flag)" } }
    $v
}

# The rule a kernel export was built under, P2 or P0, from its provenance
def rule-of [elf: any]: nothing -> any {
    if $elf == null { return null }
    let file = ($elf | path dirname | path join "provenance.nuon")
    if not ($file | path exists) { return null }
    if "P2" in (open $file | get -o symbols | default []) { "P2" } else { "P0" }
}

# The frozen exports' roles, each its file's SHA-256
def roles-of [roles: list<any>]: nothing -> list<record<role: string, sha256: string>> {
    $roles | each {|x| { role: $x.role, sha256: (open --raw $x.file | into binary | hash sha256) } }
}

# A check bound to its landed run: the run, its run.nuon's SHA-256, and its step
def check-of [c: record]: nothing -> record<check: string, run: string, run_sha256: string, step: string> {
    let why = $"a check binds no landed run: ($c | to nuon), each a check, a landed run, and its step"
    if ($c | get -o check) == null or ($c | get -o run) == null or ($c | get -o step) == null { error make { msg: $why } }
    let run = ($c.run | path expand)
    let record = ($run | path join "run.nuon")
    if not ($record | path exists) { error make { msg: $why } }
    { check: $c.check, run: $run, run_sha256: (open --raw $record | hash sha256), step: $c.step }
}

# The calibration as `calibrate` wrote it, a file or the directory holding it
def calibration-of [given: path]: nothing -> record {
    let file = (if ($given | path type) == "dir" { $given | path join "calibration.nuon" } else { $given })
    open $file
}

# An fps run read at eps: its identity, its capture measured anew by the gauge
def fps-run [place: record, vars: list<any>, eps: int]: nothing -> record {
    let dir = $place.dir
    let id = (gauge identity corrected ($dir | path join "identity.nuon")).identity
    let chosen = (gauge report legs-for $dir $id "")
    let m = (gauge measure (open --raw ($dir | path join "api.out") | into binary) $chosen.legs --cap ($id | get -o cap | default 60) --eps $eps)
    let cadence = ($id | get -o mode.cadence)
    let probed = (($id | get -o shim | default "") != "")
    let driver = ($vars | where name == "SDL_VIDEODRIVER" | get -o 0.value)
    let backend = (if ($id | get -o window | default "none") == "none" { "headless" } else if $driver == "offscreen" { "offscreen" } else { "window" })
    let target = ($id | get -o machine.spec.name)
    let probe = (if $probed { (proberuns analyse-runs [{ label: $place.label, run: 1, dir: $dir }] --eps $eps).runs.0 } else { null })
    let problems = ((proberuns capture-problems $m $cadence)
        ++ (if $m.contract.available { [] } else { [$"its receipts unread: ($m.contract.reason)"] })
        ++ (if $target == $place.declared_target { [] } else { [$"its target ($target | to nuon), its batch's ($place.declared_target)"] })
        ++ (if $probe == null or $probe.stage == null { [] } else { [$"its probe's reading stopped at its ($probe.stage): ($probe.refusals | first 3 | str join '; ')"] }))
    let run = {
        id: $place.id, dir: $dir, nonce: ($id | get -o capture_nonce), host: $place.host, target: $target,
        battery: $place.battery, workload: "fps", backend: $backend, kernel: (rule-of ($id | get -o build.kernel)),
        order: (if $cadence in [1 2] { "prepare" } else { "await" }), timing: false, probed: $probed,
        position: $place.position, seed: ($id | get -o mode.seed),
        image_sha256: ($id | get -o build.image_sha256), kernel_sha256: ($id | get -o build.kernel_sha256),
        valid: ($problems | is-empty), invalid: $problems, k_violations: $m.contract.k_violations,
        contract: { available: $m.contract.available, reason: ($m.contract.reason | default "") },
        legs: ($m.legs | each {|l| { leg: $l.leg, critical_median_ms: (ms ($l | get -o critical.median)), presented_p95_ms: (ms ($l | get -o acceptance_interval.p95)) } }),
        submission_age_median_ms: (ms ($m.whole | get -o submission_age.median)),
        late_wakes: $m.contract.late_wakes, catch_ups: $m.contract.catch_ups,
    }
    let shown = (if $probed { { shown_p95_ms: (ms ($probe | get -o whole.shown_interval.p95)) } } else { {} })
    let host = (if $probed { { render_median_us: ($probe | get -o whole.render_interval.median), presented_median_us: ($probe | get -o whole.presented_interval.median) } } else { null })
    { run: ($run | merge $shown), whole: $m.whole, host: $host }
}

# A walk run read guest-only at eps: identity, stream, interval, K, phases
def walk-run [place: record, eps: int]: nothing -> record {
    let dir = $place.dir
    let id = (open --raw ($dir | path join "identity.nuon") | into binary | decode | from nuon)
    let api = ($dir | path join "api.out")
    let bytes = (if ($api | path exists) { open --raw $api | into binary } else { 0x[] })
    let g = (reading guest-reading $bytes $id --eps $eps)
    let header = (if ($bytes | bytes length) >= $WALK_HEADER { stream header-of ($bytes | bytes at 0..<$WALK_HEADER) } else { null })
    let fl = (if $header == null { null } else { stream flags-of $header.flags })
    let target = ($id | get -o target)
    let r = $g.reading
    let problems = ((if $g.valid { [] } else { $g.faults | each {|f| $"($f.rule): ($f.examples | first 2 | str join '; ')" } })
        ++ (if $g.valid and not $g.deciding { ["a historical reading, its identity naming no build"] } else { [] })
        ++ (if $target == $place.declared_target { [] } else { [$"its target ($target | to nuon), its batch's ($place.declared_target)"] }))
    let timing = ($fl | get -o timing | default false)
    let run = {
        id: $place.id, dir: $dir, nonce: ($id | get -o capture_nonce), host: $place.host, target: $target,
        battery: $place.battery, workload: "walk", backend: (if ($id | get -o window | default "none") == "none" { "headless" } else { "window" }),
        kernel: (rule-of ($id | get -o kernel.file)), order: (if ($fl | get -o prepare | default false) { "prepare" } else { "await" }),
        timing: $timing, probed: (($id | get -o shim | default "") != ""),
        position: $place.position, seed: ($header | get -o seed),
        image_sha256: ($id | get -o image.sha256), kernel_sha256: ($id | get -o kernel.sha256),
        valid: ($problems | is-empty), invalid: $problems, k_violations: ($g.contract | get -o k.violations),
        contract: { available: $g.contract.available, reason: $g.contract.reason },
        presented_median_ms: ($r | get -o presented_interval.median_ms), presented_p95_ms: ($r | get -o presented_interval.p95_ms),
    }
    let phased = (if $timing { { d_median_ms: ($r | get -o phases.work.median_ms), phases: ($r | get -o phases) } } else { {} })
    { run: ($run | merge $phased), whole: null, host: null }
}

# A battery's runs in its order, each at its target's position, read at eps
def battery-of [b: record, eps: int]: nothing -> list<record> {
    let base = ($b.base | path expand)
    let batches = (open ($base | path join "batches.nuon"))
    let walked = ("image" in ($batches | columns))
    let declared = ($batches | each {|x|
        if $walked { { label: $x.label, target: $x.spec, runs: $x.runs, env: [] } } else {
            { label: $x.label, target: (word-of $x.words "--spec" $x.label), runs: (word-of $x.words "--runs" $x.label | into int), env: $x.env }
        }
    })
    $declared | enumerate | each {|e|
        let x = $e.item
        let before = ($declared | first $e.index | where target == $x.target | each {|y| $y.runs } | append 0 | math sum)
        let dirs = (glob ($base | path join $x.label "run_*") | where {|d| ($d | path type) == "dir" and (($d | path basename) =~ '^run_[0-9]+$') } | each {|d| { n: ($d | path basename | str substring 4.. | into int), dir: $d } } | sort-by n)
        $dirs | each {|d|
            let place = { id: $"($b.host)/($b.battery)/($x.label)/run_($d.n)", dir: $d.dir, host: $b.host, battery: $b.battery, label: $x.label, declared_target: $x.target, position: ($before + $d.n) }
            let read = (if $walked { walk-run $place $eps } else { fps-run $place $x.env $eps })
            print $"timing readings: ($place.id): (if $read.run.valid { 'valid' } else { 'invalid, ' + ($read.run.invalid | str join '; ') }), K ($read.run.k_violations | to nuon)"
            $read
        }
    } | flatten
}

# Two arms' effect on a statistic of their valid runs, and its noise
def effect-of [measure: string, on: list<any>, off: list<any>, stat: closure]: nothing -> record {
    let a = ($on | each {|r| do $stat $r } | compact)
    let b = ($off | each {|r| do $stat $r } | compact)
    let range = {|v: list<any>| if ($v | is-empty) { null } else { ($v | math max) - ($v | math min) } }
    let ranges = ([(do $range $a) (do $range $b)] | compact)
    let first = (rank $a 0.5)
    let second = (rank $b 0.5)
    let effect = (if $first == null or $second == null { null } else { $first - $second })
    let noise = (if ($ranges | length) < 2 { null } else { ($ranges | math max) / 2 })
    { measure: $measure, on: $first, off: $second, effect: $effect, noise: $noise, within: ($effect != null and $noise != null and ($effect | math abs) <= $noise) }
}

# The shim's controls, ProbeRuns' observer effect over probed and plain runs
def shim-controls [read: list<any>]: nothing -> list<any> {
    let fps = ($read | where {|x| $x.run.workload == "fps" })
    $fps | group-by {|x| $"($x.run.host)/($x.run.target)/($x.run.battery)/($x.run.kernel)" } | values | each {|g|
        let probed = ($g | where {|x| $x.run.probed })
        let plain = ($g | where {|x| not $x.run.probed })
        if ($probed | is-empty) or ($plain | is-empty) { null } else {
            let arm = {|xs: list<any>| $xs | where {|x| $x.run.valid } | each {|x| { name: $x.run.id, whole: $x.whole } } }
            let e = (observer shim-effect (do $arm $probed) (do $arm $plain))
            let r = ($g | first | get run)
            { kind: "shim", host: $r.host, target: $r.target, kernel: $r.kernel, runs: ($g | each {|x| $x.run.id }), passing: ($e.admissible and ($g | all {|x| $x.run.valid })), effects: ($e.measures | reject -o runs), problems: $e.problems }
        }
    } | compact
}

# The TIMING controls: walk's presented interval, TIMING on against off
def timing-controls [read: list<any>]: nothing -> list<any> {
    let walks = ($read | where {|x| $x.run.workload == "walk" })
    $walks | group-by {|x| $"($x.run.host)/($x.run.target)/($x.run.battery)/($x.run.kernel)/($x.run.order)" } | values | each {|g|
        let on = ($g | where {|x| $x.run.timing } | where {|x| $x.run.valid } | get run)
        let off = ($g | where {|x| not $x.run.timing } | where {|x| $x.run.valid } | get run)
        if ($g | all {|x| $x.run.timing }) or ($g | all {|x| not $x.run.timing }) { null } else {
            let effects = [
                (effect-of "presented interval median" $on $off {|r| $r.presented_median_ms })
                (effect-of "presented interval 95th" $on $off {|r| $r.presented_p95_ms })
            ]
            let r = ($g | first | get run)
            { kind: "timing", host: $r.host, target: $r.target, kernel: $r.kernel, order: $r.order, runs: ($g | each {|x| $x.run.id }), passing: (($g | all {|x| $x.run.valid }) and ($effects | all {|f| $f.within })), effects: $effects }
        }
    } | compact
}

# The hosts' display limits, where SDL's renders lag the guest's presents
def host-limits [read: list<any>, controls: list<any>]: nothing -> list<any> {
    let probed = ($read | where {|x| $x.run.workload == "fps" and $x.run.probed })
    let half_us = ($PERIOD / $US_TICKS / 2)
    $probed | group-by {|x| $"($x.run.host)/($x.run.target)/($x.run.battery)" } | values | each {|g|
        let r = ($g | first | get run)
        let kernels = ($g | each {|x| $x.run.kernel } | uniq | sort)
        let figures = ($g | each {|x| { run: $x.run.id, kernel: $x.run.kernel, render_median_us: ($x.host | get -o render_median_us), presented_median_us: ($x.host | get -o presented_median_us) } })
        let found = ($figures | all {|f| $f.render_median_us != null and $f.presented_median_us != null and $f.render_median_us > ($f.presented_median_us + $half_us) })
        if $kernels != ["P0" "P2"] or not $found { null } else {
            let admitted = ($kernels | all {|k| $controls | any {|c| $c.kind == "shim" and $c.host == $r.host and $c.target == $r.target and $c.kernel == $k and $c.passing } })
            { host: $r.host, target: $r.target, admissible: $admitted, limit: { rule: "SDL's render interval's median past the guest's presented interval's median by more than half a period on every probed run", figures: $figures }, runs: ($g | each {|x| $x.run.id }) }
        }
    } | compact
}

# The readings a comparison's captures give, assembled from a spec
export def main [spec: path, out: path]: nothing -> nothing {
    let assembler = (identity reader [$STRESS $JAB])
    let s = (open $spec)
    if not (($s.checks | describe) | str starts-with "table") { error make { msg: "the spec's checks are no table of landed runs; each a check, a landed run, and its step" } }
    let checks = ($s.checks | each {|c| check-of $c })
    let cal = (calibration-of $s.calibration)
    if $cal.eps == null { error make { msg: $"the calibration is ($cal.state): no eps to read the runs at" } }
    let read = ($s.batteries | each {|b| battery-of $b $cal.eps } | flatten)
    let shim = (shim-controls $read)
    let readings = {
        strategy: $s.strategy
        checks: $checks
        calibration: { state: $cal.state, eps: $cal.eps, qualifying: $cal.qualifying }
        freeze: { images: (roles-of $s.freeze.images), kernels: (roles-of $s.freeze.kernels) }
        runs: ($read | each {|x| $x.run })
        controls: ($shim ++ (timing-controls $read))
        host_limits: (host-limits $read $shim)
        spec: ($spec | path expand)
        assembler: $assembler
    }
    mkdir $out
    $readings | to nuon --indent 1 | save --raw -f ($out | path join "readings.nuon")
    let valid = ($readings.runs | where valid | length)
    print $"timing readings: ($readings.runs | length) runs, ($valid) valid, at eps ($cal.eps); ($readings.controls | length) controls, ($readings.controls | where passing | length) passing; ($readings.host_limits | length) host limits"
    for c in $readings.controls { print $"  ($c.kind) control of ($c.host) ($c.target) ($c.kernel): (if $c.passing { 'passing' } else { 'failing' })" }
    for l in $readings.host_limits { print $"  host limit of ($l.host) ($l.target): (if $l.admissible { 'admissible' } else { 'inadmissible' })" }
}
