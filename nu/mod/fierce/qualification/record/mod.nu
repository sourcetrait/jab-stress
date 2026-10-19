use (path self ../../../../../../jab/nu/mod/spec)
use (path self ../../../../../../jab/nu/mod/identity)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../observer)
use (path self ../../proberuns)
use (path self ../check)
use (path self ../matrix)
use (path self ../matrix) [CASES DIAGNOSTICS JAB LIMITS RECORD STRESS TARGETS]

# The value after a flag among a step's words, null where it is absent
def flag-of [words: list<string>, flag: string]: nothing -> any {
    let at = ($words | enumerate | where item == $flag | get -o 0.index)
    if $at == null { null } else { $words | get -o ($at + 1) }
}

# The runs a step's words ask for, the gauge's defaults where none named
export def expected-of [words: list<string>]: nothing -> record<kind: string, runs: list<any>> {
    let verb = ($words | get -o 1)
    if $verb == "play" {
        return { kind: "play", runs: [{ run: 1, seed: (flag-of $words "--seed" | default "1" | into int) }] }
    }
    let count = (flag-of $words "--runs" | default "3" | into int)
    let seeds = (flag-of $words "--seeds" | default "[]" | from nuon)
    { kind: "route", runs: (1..$count | each {|n| { run: $n, seed: ($seeds | get -o ($n - 1) | default $n) } }) }
}

# A run's identity as the record keeps it, from its run request
def identity-summary [req: record]: nothing -> record {
    let id = $req.identity
    {
        from: $req.from, binding: ($req.binding | get -o strength), file: $req.file, sha256: $req.identity_sha256,
        tree: ($id | get -o build.tree), flags: ($id | get -o build.flags),
        image_sha256: ($id | get -o build.image_sha256), elf_sha256: ($id | get -o build.elf_sha256), kernel_sha256: ($id | get -o build.kernel_sha256),
        assets: { map: ($id | get -o assets.map), digest: ($id | get -o assets.digest) },
        workspace: ($id | get -o workspace), program: ($id | get -o program),
        machine: ($id | get -o machine), overrides: ($id | get -o overrides | default []), cap: ($id | get -o cap),
        qemu: ($id | get -o qemu), toolchain: ($id | get -o toolchain), host: ($id | get -o host),
        mode: ($id | get -o mode), shim: ($id | get -o shim | default ""), capture_nonce: ($id | get -o capture_nonce),
    }
}

# A run's directory as its report's run-dirs find it, null for none
def dir-of [file: path, r: record]: nothing -> any {
    gauge identity dirs $file $r | where {|d| ($d | path type) == "dir" } | get -o 0
}

# A bench step's runs as the record keeps them
def step-runs [step: record, doc: record, candidate: record, target: string, spec: record]: nothing -> list<any> {
    if $step.file == null { return [] }
    let g = (open $step.file)
    $g.runs | each {|r|
        let req = (gauge identity request $step.file $r ($g | get -o identity))
        let classed = ($doc.runs | where {|x| $x.label == $step.label and $x.run == $r.run } | get -o 0)
        let id = (identity-summary $req)
        let dir = (dir-of $step.file $r)
        let bundle = (if $dir == null { null } else { $dir | path join "bundle" })
        {
            step: $step.label, run: $r.run, seed: ($r | get -o seed),
            kind: ($classed | get -o kind), selection: $req.selection, cadence: $req.cadence, workers: $req.workers, grain: $req.grain,
            standing: ($classed | get -o standing | default "unclassified"), reasons: ($classed | get -o reasons | default []),
            probed: $req.probed, dir: $dir, bundle: (if $bundle != null and ($bundle | path type) == "dir" { $bundle } else { null }),
            identity: $id, agreement: (matrix agreement-of $id $candidate $target $spec),
            measured: ($r | get -o measured), cpu: ($r | get -o cpu),
        }
    }
}

# The bench run held to the candidate's bench file, each problem named
def bench-problems [listed: record, definition: any]: nothing -> list<string> {
    if $definition == null { return ["the candidate's commit holds no bench file for this target"] }
    let ran = ($listed.steps | get label)
    let defined = ($definition.steps | get label)
    let unrun = ($defined | where {|l| $l not-in $ran } | each {|l| $"step ($l) of the candidate's bench was not run" })
    let foreign = ($ran | where {|l| $l not-in $defined } | each {|l| $"step ($l) is no step of the candidate's bench" })
    let reworded = ($listed.steps | each {|s|
        let d = ($definition.steps | where label == $s.label | get -o 0)
        if $d != null and $d.run != $s.run { $"step ($s.label) ran ($s.run | str join ' ') where the candidate's bench runs ($d.run | str join ' ')" }
    } | compact)
    let undone = ($listed.steps | where {|s| $s.state != "done" } | each {|s| $"step ($s.label) ended ($s.state)(if ($s | get -o exit) == null { '' } else { $', exit ($s.exit)' })" })
    $unrun ++ $foreign ++ $reworded ++ $undone
}

# A case's expected runs, each found or missing, a reseeded one named
def expected-runs [labels: list<string>, listed: record, definition: any, runs: list<any>]: nothing -> record<expected: list<any>, missing: list<any>, problems: list<string>> {
    let expected = ($labels | each {|l|
        let words = ($listed.steps | where label == $l | get -o 0.run | default ($definition | get -o steps | default [] | where label == $l | get -o 0.run))
        if $words == null { [] } else { (expected-of $words).runs | each {|e| $e | insert step $l } }
    } | flatten)
    let missing = ($expected | where {|e| ($runs | where {|r| $r.step == $e.step and $r.run == $e.run } | is-empty) })
    let reseeded = ($expected | each {|e|
        let found = ($runs | where {|r| $r.step == $e.step and $r.run == $e.run } | get -o 0)
        if $found != null and $found.seed != $e.seed { $"($e.step) run ($e.run) played seed ($found.seed) where its step asks ($e.seed)" }
    } | compact)
    { expected: $expected, missing: $missing, problems: $reseeded }
}

# Why a control's runs leave it unmet, each named
def control-problems [runs: list<any>, missing: list<any>, target: string]: nothing -> list<string> {
    let absent = ($missing | each {|m| $"($m.step) run ($m.run) is missing" })
    let unfit = ($runs | where standing != "valid" | each {|r| $"(matrix run-name $r) stands ($r.standing): ($r.reasons | str join '; ')" })
    let foreign = ($runs | where {|r| not ($r.agreement | is-empty) } | each {|r| $"(matrix run-name $r) is not the candidate's run on ($target): ($r.agreement | str join '; ')" })
    $absent ++ $unfit ++ $foreign
}

# The shim control's reading: the shim's effect over its two arms
def shim-reading [runs: list<any>, missing: list<any>, target: string]: nothing -> record {
    let fit = ($runs | where {|r| $r.standing == "valid" and ($r.agreement | is-empty) })
    let arm = {|probed: bool| $fit | where probed == $probed | each {|r| { name: (matrix run-name $r), whole: $r.measured.whole } } }
    let effect = (observer shim-effect (do $arm true) (do $arm false))
    let problems = ((control-problems $runs $missing $target) ++ $effect.problems)
    { met: ($problems | is-empty), admissible: $effect.admissible, measures: $effect.measures, problems: $problems }
}

# The worker scaling control's reading: forced against automatic, by leg
def scaling-reading [runs: list<any>, missing: list<any>, target: string]: nothing -> record {
    let unread = ($runs | where {|r| ($r.cpu | get -o whole.missing | default true) } | each {|r| $"(matrix run-name $r) holds no CPU window over its whole run" })
    let legs = ($runs | each {|r| $r.measured | get -o legs | default [] | get leg } | flatten | uniq)
    let by_leg = ($legs | each {|leg|
        {
            leg: $leg,
            runs: ($runs | each {|r|
                let l = ($r.measured | get -o legs | default [] | where leg == $leg | get -o 0)
                { name: (matrix run-name $r), selection: $r.selection, workers: $r.workers, critical_us: ($l | get -o critical.median), raster_us: ($l | get -o raster.median) }
            }),
        }
    })
    let harts = ($runs | each {|r|
        { name: (matrix run-name $r), selection: $r.selection, workers: $r.workers, interval: ($r.cpu | get -o whole.interval), threads: ($r.cpu | get -o whole.threads | default [] | each {|t| { name: $t.name, utilization: $t.utilization } }) }
    })
    let problems = ((control-problems $runs $missing $target) ++ $unread)
    { met: ($problems | is-empty), legs: $by_leg, harts: $harts, problems: $problems }
}

# The presentation's reading: ProbeRuns' reader over the probed runs by directory
def presentation-reading [runs: list<any>, missing: list<any>, target: string]: nothing -> record {
    let unbundled = ($runs | where {|r| $r.bundle == null or (not $r.probed) })
    let named = ($runs | where {|r| $r.standing != "valid" or (not ($r.agreement | is-empty)) } | append $unbundled | each {|r| matrix run-name $r })
    let reading = (proberuns analyse-runs ($runs | each {|r| { label: $r.step, run: $r.run, dir: $r.dir } }))
    let unread = ($reading.unread | where {|u| $"($u.label) run ($u.run)" not-in $named } | each {|u| $"($u.label) run ($u.run) is unread at its ($u.stage): ($u.refusals | str join '; ')" })
    let problems = ((control-problems $runs $missing $target) ++ ($unbundled | each {|r| $"(matrix run-name $r) holds no bundle of the sdl shim's" }) ++ $unread)
    {
        read: ($problems | is-empty),
        bundles: ($runs | each {|r| { name: (matrix run-name $r), probed: $r.probed, bundle: $r.bundle } }),
        runs: $reading.runs,
        cadences: $reading.cadences,
        unread: $reading.unread,
        limits: $reading.limits,
        problems: $problems,
    }
}

# A diagnostic's readings from the normal play runs, a missing leg named
def diagnostic-reading [d: record, runs: list<any>]: nothing -> record {
    let readings = ($runs | each {|r|
        let held = ($r.measured | get -o legs | default [])
        let wanted = (if ($d.legs | is-empty) { $held | get leg } else { $d.legs })
        $wanted | each {|leg|
            let l = ($held | where leg == $leg | get -o 0)
            if $l == null { { name: (matrix run-name $r), leg: $leg, missing: true, fields: null } } else {
                { name: (matrix run-name $r), leg: $leg, missing: false, fields: ($d.fields | reduce --fold {} {|f, acc| $acc | insert $f ($l | get -o $f) }) }
            }
        }
    } | flatten)
    { case: $d.case, legs: $d.legs, fields: $d.fields, readings: $readings, missing: ($readings | where missing | each {|x| $"($x.name) holds no ($x.leg) leg" }) }
}

# The program's RAM window at the candidate's commit beside the target's
def ram-of [commit: string, spec: record]: nothing -> record {
    let inc = (matrix jab-file $commit "sdk/src/jab.inc")
    let size = (if $inc == null { null } else { $inc | lines | parse --regex '^\s*\.set JAB_PROGRAM_SIZE, 0x(?P<v>[0-9a-fA-F]+)' | get -o 0.v })
    let window = (if $size == null { null } else { $size | into int --radix 16 })
    { installed_bytes: ($spec.ram | into int), window_bytes: $window }
}

# The watch's record of a bench run, null where it ran unwatched
def watch-of [bench: path]: nothing -> any {
    let file = ($bench | path join "watch.nuon")
    if ($file | path exists) { open $file } else { null }
}

# One target's qualification record from a bench run
export def record-of [bench: path, candidate: path, target: string]: nothing -> record {
    let target = ($target | str lowercase)
    if $target not-in $TARGETS { error make { msg: $"($target) is no target of the qualification's matrix, which holds ($TARGETS | str join ', ')" } }
    let bench = ($bench | path expand)
    let listed_file = ($bench | path join "bench.nuon")
    if not ($listed_file | path exists) { error make { msg: $"($bench) holds no bench.nuon, so it is no bench run's directory" } }
    let listed = (open $listed_file)
    let cand = (open --raw $candidate | decode utf-8 | from nuon)
    let spec = (spec row $JAB $target)
    let defined = (matrix jab-file $cand.jab $"kit/fierce/bench/qual_($target).nuon"
        | default (matrix jab-file $cand.jab $"game/fps/bench/qual_($target).nuon"))
    let definition = (if $defined == null { null } else { $defined | from nuon })
    let doc = (gauge bench doc $bench)
    let runs = ($doc.steps | each {|s| step-runs $s $doc $cand $target $spec } | flatten)
    let runs = ($runs | each {|r|
        let acceptance = ($CASES | where kind == acceptance | any {|c| $r.step in ($c.steps | get $target) })
        if $acceptance { $r | insert verdict (matrix verdict-of $r) } else { $r }
    })
    let cases = ($CASES | each {|c|
        let labels = ($c.steps | get $target)
        let these = ($runs | where {|r| $r.step in $labels })
        let e = (expected-runs $labels $listed $definition $these)
        let reading = (match $c.reading {
            "verdicts" => ({ passed: ($these | where {|r| $r.verdict.pass } | length), runs: ($these | length) })
            "presentation" => (presentation-reading $these $e.missing $target)
            "shim" => (shim-reading $these $e.missing $target)
            "scaling" => (scaling-reading $these $e.missing $target)
        })
        { case: $c.case, kind: $c.kind, steps: $labels, runs: ($these | each {|r| { step: $r.step, run: $r.run } }), expected: $e.expected, missing: $e.missing, problems: $e.problems, reading: $reading }
    })
    let normal = ($CASES | where case == "normal play" | get 0.steps | get $target)
    let routed = ($runs | where {|r| $r.step in $normal and $r.kind == "route" })
    {
        target: $target,
        written: (date now | format date "%Y-%m-%dT%H:%M:%S%z"),
        readers: (identity reader [$STRESS $JAB] --launches),
        candidate: ($cand | insert file ($candidate | path expand) | insert sha256 (matrix sha-of $candidate)),
        spec: { name: $spec.name, cores: $spec.cores, ram_bytes: ($spec.ram | into int), display: $spec.display, fps: $spec.fps },
        bench: {
            dir: $bench, bench: ($listed | get -o bench), stamp: ($listed | get -o stamp), state: ($listed | get -o state), file: ($listed | get -o file),
            steps: ($listed.steps | each {|s|
                let file = ($bench | path join $s.label "gauge.nuon")
                { label: $s.label, state: $s.state, exit: ($s | get -o exit), seconds: ($s | get -o seconds), run: $s.run, gauge: (if ($file | path exists) { $file } else { null }), gauge_sha256: (matrix sha-of $file) }
            }),
            problems: (bench-problems $listed $definition),
        },
        hosts: {
            hosts: ($runs | each {|r| $r.identity.host } | uniq),
            qemus: ($runs | each {|r| $r.identity.qemu } | uniq),
            toolchains: ($runs | each {|r| $r.identity.toolchain } | uniq),
            machines: ($runs | each {|r| $r.identity.machine } | uniq),
        },
        watch: (watch-of $bench),
        ram: (ram-of $cand.jab $spec),
        runs: $runs,
        cases: $cases,
        diagnostics: ($DIAGNOSTICS | each {|d| diagnostic-reading $d $routed }),
        limits: $LIMITS,
    }
}

# A target's record written to `out`, its check's problems printed
export def main [bench: path, candidate: path, target: string, out: path] {
    mkdir $out
    let r = (record-of $bench $candidate $target)
    let file = ($out | path join $RECORD)
    $r | to nuon --indent 1 | save --raw $file
    let problems = (check check-of $r)
    print $"qualification: ($r.target), ($r.runs | length) runs, ($problems | length) problems the check names; ($file)"
}
