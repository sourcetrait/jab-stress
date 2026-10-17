# qualification.nu: FrameCeiling's Qualification, the closing acceptance
# against actual play on both targets (FrameCeiling/Qualification.md).
# `candidate` builds the release tree and writes the candidate's record at
# its freeze. `record` reads one target's bench run, a run of the game's
# bench/qual_<target>.nuon, through gauge.nu's bench-doc and every run
# through run-request, into the target's qualification record: the
# candidate, the bench against the candidate's bench file, every run with
# its standing, its identity, and that identity's agreement with the
# candidate and the target, each case of the matrix with its runs, every
# acceptance run's verdict, the controls' readings and the diagnostics'
# apart, the host, and the limits stated. `check` holds a record to the
# schema and the acceptance, every problem named. `report` writes the
# document for TheUser, a section a target. `holds` runs all of it over
# synthetic bench runs it writes. Run under the real nu: `nu
# qualification.nu <command> ...` (`fps/just/qualification.just`).
use ../../../jab/sdk/nu/jab.nu
use ../../../jab/game/fps/test/gauge.nu
use ../../../jab/game/fps/test/test.nu [fx-items fx-bytes fx-set fx-set-all FX_PERIOD]
use ./observer.nu
use std/assert

# jab checked out beside this repository, and this repository
const JAB = (path self | path dirname | path join .. .. .. jab | path expand)
const STRESS = (path self | path dirname | path join .. .. | path expand)
# this file, whose SHA-256 a record carries
const SELF = (path self)
# the qualification's targets, each a named spec (the matrix)
const TARGETS = ["1ka1" "1kb1"]
# the map every run plays
const MAP = "render_0"
# the record's file in its directory
const RECORD = "qualification.nuon"

# The matrix's cases a bench run holds: each its kind, acceptance,
# diagnostic, or control; the reading it takes, every run's verdict, the
# probed runs' bundles, the shim control (observer.nu), or the scaling
# control; and each target's steps. The matrix's other rows join with the
# machinery they run on: the service-active case and the unavailable
# feature with SceneOwnership's synthetic service, the audio with
# RegressionSuite's service-holds.
const CASES = [
    [case, kind, reading, steps];
    ["normal play", acceptance, verdicts, {"1ka1": [auto_1 auto_2], "1kb1": [auto_1 auto_2]}]
    ["free play", acceptance, verdicts, {"1ka1": [free], "1kb1": [free]}]
    ["presentation", diagnostic, bundles, {"1ka1": [probed_1 probed_2], "1kb1": [probed_1 probed_2]}]
    ["presentation's shim control", control, shim, {"1ka1": [probed_1 auto_3 auto_4 probed_2], "1kb1": [probed_1 auto_3 auto_4 probed_2]}]
    ["worker scaling", control, scaling, {"1ka1": [forced1_1 auto_5 auto_6 forced1_2], "1kb1": [forced2_1 auto_5 auto_6 forced2_2]}]
]

# The diagnostics read from the normal play runs' own frames (the matrix's
# diagnostic rows): each its route legs, every leg a run holds where it
# names none, and the fields of a leg's summary (gauge.nu's leg-summary).
const DIAGNOSTICS = [
    [case, legs, fields];
    ["first sight", [start], [frames over critical draw preparation raster tiles tiles_built building_frames tiled_pixels fallback_pixels]]
    ["revisits and turns", [spawn revisit], [frames over critical draw preparation raster tiles tiles_built building_frames tiled_pixels fallback_pixels]]
    ["stairs", [up down], [frames over critical draw preparation raster tiled_pixels fallback_pixels]]
    ["masks", [yard], [frames over critical draw preparation raster tiled_pixels fallback_pixels]]
    ["actors and the fight", [fight], [frames over critical draw sprites]]
    ["cold and steady", [], [frames tiles tiles_built building_frames evicted missed_blocks slots_used_max build overrun]]
    ["pressure and eviction", [pressure], [frames over critical tiles_built evicted slots_used_max ring_fill_max memory_peak build overrun]]
    ["worker balance", [], [frames workers grains raster slowest busy dispatch barrier]]
]

# What a qualification record cannot claim (Qualification.md's presentation,
# CPU, and audio), stated with every reading.
const LIMITS = [
    "The physical display is not qualified. TheUser's eye is a qualitative reading and never a measured 60 frames a second."
    "A thread's CPU comes from its host's counters, hundredths of a second read every 100 ms, so only an interval of seconds resolves. One less a thread's utilization is everything it did not run, descheduling included, and is never the guest's idle time; the guest's own waits come from its records."
    "Upload and render selection come from the probed runs alone. They stand for the unprobed program's presentation only where the shim control finds every effect within its noise."
    "A release run carries no sound counters. The audio's evidence comes from separate debug runs, labelled diagnostic."
]

# A file's SHA-256, null where there is none.
def sha-of [file: path]: nothing -> any {
    if ($file | path exists) { open --raw $file | hash sha256 } else { null }
}

# A repository's HEAD in full, and whether its tree holds changes.
def head-of [repo: path]: nothing -> record<commit: string, dirty: bool> {
    let commit = (^git -C $repo rev-parse HEAD | complete | get stdout | str trim)
    let dirty = ((^git -C $repo status --porcelain | complete | get stdout | str trim) != "")
    { commit: $commit, dirty: $dirty }
}

# A file of jab's at a commit, its text, null where the commit holds none.
def jab-file [commit: string, file: string]: nothing -> any {
    let shown = (^git -C $JAB show $"($commit):($file)" | complete)
    if $shown.exit_code != 0 { null } else { $shown.stdout }
}

# Milliseconds to a tenth from microseconds, a dash for none.
def ms [us: any]: nothing -> string {
    if $us == null { "-" } else { $"(($us / 1000.0) | math round --precision 1)" }
}

# A commit shortened for reading.
def short [commit: any]: nothing -> string {
    if $commit == null { "none" } else { $commit | str substring 0..<10 }
}

# The candidate at its freeze (Qualification.md's freeze): the release
# tree built at jab's HEAD (`jab.nu build`), then jab's commit and this
# repository's, each its checkout's HEAD with no changes, `tag` naming both
# when given and refused unless it names each HEAD; the release fps image,
# its ELF, and the kernel built with it, each by its SHA-256, the image's
# flags free of DEBUG; the toolchain those flags name, each tool the file
# its prefix resolves to with that file's SHA-256 (gauge.nu's
# resolved-file); and Render Zero's asset tree by gauge.nu's digest, the
# tree every run plays.
export def candidate-of [tag: string]: nothing -> record {
    let repos = [[repo, dir]; [jab $JAB] [stress $STRESS]]
    let heads = ($repos | each {|r|
        let h = (head-of $r.dir)
        if $h.dirty { error make { msg: $"($r.dir) holds changes; a candidate is a commit with every file of it committed" } }
        if $tag != "" {
            let named = (^git -C $r.dir rev-parse $"($tag)^{commit}" | complete)
            if $named.exit_code != 0 { error make { msg: $"($r.dir) has no tag ($tag)" } }
            if ($named.stdout | str trim) != $h.commit { error make { msg: $"($tag) names ($named.stdout | str trim) in ($r.dir), whose HEAD is ($h.commit)" } }
        }
        { repo: $r.repo, commit: $h.commit }
    })
    let game = ($JAB | path join game fps)
    let built = (^nu ($JAB | path join sdk nu jab.nu) build $game | complete)
    if $built.exit_code != 0 { error make { msg: $"the release build of ($game): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
    let out = (jab program-out $game release)
    let image = ($out | path join fps.jab)
    let elf = ($out | path join fps.elf)
    let kernel = (jab program-kernel $game release)
    for f in [$image $elf $kernel] { if not ($f | path exists) { error make { msg: $"the release build left no ($f)" } } }
    let flags = (open --raw ($out | path join flags) | decode | lines | first)
    if ($flags =~ '--defsym DEBUG=') { error make { msg: $"the release image's flags define DEBUG: ($flags)" } }
    let prefix = ($flags | split row " " | last)
    {
        tag: (if $tag == "" { null } else { $tag }),
        written: (date now | format date "%Y-%m-%dT%H:%M:%S%z"),
        jab: ($heads | where repo == jab | get 0.commit),
        stress: ($heads | where repo == stress | get 0.commit),
        image_sha256: (sha-of $image),
        elf_sha256: (sha-of $elf),
        kernel_sha256: (sha-of $kernel),
        flags: $flags,
        toolchain: {
            prefix: $prefix,
            version: (try { ^$"($prefix)as" --version | complete | get stdout | lines | get -o 0 } catch { null }),
            tools: { as: (gauge resolved-file $"($prefix)as"), ld: (gauge resolved-file $"($prefix)ld"), objcopy: (gauge resolved-file $"($prefix)objcopy") },
        },
        assets: { map: $MAP, digest: (gauge tree-digest (jab program-shard $game asset | path join $MAP)) },
    }
}

# The value after a flag among a step's words, null where it is absent.
def flag-of [words: list<string>, flag: string]: nothing -> any {
    let at = ($words | enumerate | where item == $flag | get -o 0.index)
    if $at == null { null } else { $words | get -o ($at + 1) }
}

# The runs a step's words ask for, gauge.nu's defaults where they name
# none: `run` its `--runs`, 3 unless given, each run n played at its n of
# `--seeds`, else n; `play` one run at its `--seed`, else 1.
export def expected-of [words: list<string>]: nothing -> record<kind: string, runs: list<any>> {
    let verb = ($words | get -o 1)
    if $verb == "play" {
        return { kind: "play", runs: [{ run: 1, seed: (flag-of $words "--seed" | default "1" | into int) }] }
    }
    let count = (flag-of $words "--runs" | default "3" | into int)
    let seeds = (flag-of $words "--seeds" | default "[]" | from nuon)
    { kind: "route", runs: (1..$count | each {|n| { run: $n, seed: ($seeds | get -o ($n - 1) | default $n) } }) }
}

# A run's identity as the record keeps it, from the identity run-request
# resolved: its source, binding, and recorded SHA-256; the build's tree,
# flags, and the image's, ELF's, and kernel's SHA-256; the assets; the
# workspace's and the program's commits; the machine; the cap; the QEMU;
# the toolchain; the host; the mode; and the capture's shim and nonce.
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

# Whether a commit as an identity records it, shortened or whole, is the
# candidate's.
def same-commit [recorded: any, candidate: string]: nothing -> bool {
    $recorded != null and ($recorded | str length) >= 7 and ($candidate | str starts-with $recorded)
}

# Where a run's identity disagrees with the candidate and the target, each
# disagreement named: the image's, the ELF's, and the kernel's SHA-256;
# the assets' map and digest; the workspace's and the program's commits
# and their changes; the machine, the target's named spec with its cores,
# RAM, and display, never a custom machine or QEMU words of its own; the
# cap, the target's frame rate; and the release tree.
export def agreement-of [id: record, candidate: record, target: string, spec: record]: nothing -> list<string> {
    let m = ($id.machine | default {})
    let named = ($m | get -o spec)
    let program = ($id.program | default {})
    let workspace = ($id.workspace | default {})
    let program_commit = ($program | get -o commit)
    [
        (if $id.image_sha256 != $candidate.image_sha256 { $"its image's SHA-256 is ($id.image_sha256 | default 'unrecorded') where the candidate's is ($candidate.image_sha256)" })
        (if $id.elf_sha256 != $candidate.elf_sha256 { $"its ELF's SHA-256 is ($id.elf_sha256 | default 'unrecorded') where the candidate's is ($candidate.elf_sha256)" })
        (if $id.kernel_sha256 != $candidate.kernel_sha256 { $"its kernel's SHA-256 is ($id.kernel_sha256 | default 'unrecorded') where the candidate's is ($candidate.kernel_sha256)" })
        (if $id.assets.map != $candidate.assets.map { $"it played the map ($id.assets.map | default 'unrecorded') where the candidate's is ($candidate.assets.map)" })
        (if $id.assets.digest != $candidate.assets.digest { $"its asset tree's digest is ($id.assets.digest | default 'unrecorded') where the candidate's is ($candidate.assets.digest)" })
        (if not (same-commit ($workspace | get -o commit) $candidate.jab) { $"its workspace is at ($workspace | get -o commit | default 'an unrecorded commit') where the candidate is at (short $candidate.jab)" })
        (if ($workspace | get -o dirty) != false { "its workspace held changes or recorded none" })
        (if ($program | get -o from) == "source.nuon" {
            if $program_commit != $candidate.jab { $"its program's source is ($program_commit | default 'unrecorded') where the candidate is ($candidate.jab)" }
        } else if not (same-commit $program_commit $candidate.jab) {
            $"its program's source is at ($program_commit | default 'an unrecorded commit') where the candidate is at (short $candidate.jab)"
        } else if ($program | get -o dirty) != false { "its program's files held changes or recorded none" })
        (if (($named | describe) | str starts-with "record") {
            if $named.name != $target { $"it was launched as ($named.name), not the target ($target)" }
        } else { "its machine is no named spec's: a custom or unrecorded machine is never a qualification run" })
        (if ($m | get -o diagnostic) != null { "its machine is a custom machine, diagnostic" })
        (if not (($id.overrides | default []) | is-empty) { $"its launch carried QEMU words of its own: ($id.overrides | str join ' ')" })
        (if ($m | get -o harts) != $spec.cores { $"its machine has ($m | get -o harts | default 'unrecorded') harts where ($target) has ($spec.cores)" })
        (if ($m | get -o ram_gib) != ($spec.ram / 1GiB | into int) { $"its machine has ($m | get -o ram_gib | default 'unrecorded') GiB where ($target) has ($spec.ram / 1GiB | into int)" })
        (if ($named | get -o display) != $spec.display { $"its display is ($named | get -o display | to nuon) where ($target)'s is ($spec.display | to nuon)" })
        (if $id.cap != $spec.fps { $"its cap is ($id.cap | default 'unrecorded') where ($target)'s frame rate is ($spec.fps)" })
        (if $id.tree != "release" { $"its build is the ($id.tree | default 'unrecorded') tree, not release" })
    ] | compact
}

# An acceptance run's verdict (Qualification.md's acceptance): it passes
# when it stands valid, its identity agrees with the candidate and the
# target, and its critical path's median over its play frames is under
# the ceiling by gauge.nu's under-ceiling, the one rule; every problem
# named; the median and the tail beside it.
export def verdict-of [run: record]: nothing -> record {
    let whole = ($run.measured | get -o whole)
    let median = ($whole | get -o critical.median)
    let under = (if $run.standing == "valid" and $median != null { gauge under-ceiling $median } else { null })
    let problems = ([
        (if $run.standing != "valid" { $"it stands ($run.standing): ($run.reasons | str join '; ')" })
        ...$run.agreement
        (if $under == false { $"its critical path's median, (ms $median) ms, is at or over the ($gauge.CEILING_US // 1000) ms ceiling" })
    ] | compact)
    { pass: ($problems | is-empty), median_us: $median, ceiling_us: $gauge.CEILING_US, under: $under, over: ($run.measured | get -o over), frames: ($run.measured | get -o frames), problems: $problems }
}

# A run's directory as its report's run-dirs find it, null where none is.
def dir-of [file: path, r: record]: nothing -> any {
    gauge run-dirs $file $r | where {|d| ($d | path type) == "dir" } | get -o 0
}

# A bench step's runs as the record keeps them (record-of): each run of
# its gauge.nuon read through run-request, its standing and reasons as the
# bench-doc classified it, its identity (identity-summary) and that
# identity's agreement with the candidate and the target (agreement-of),
# whether it was probed, its bundle, its measurement, and its CPU windows.
def step-runs [step: record, doc: record, candidate: record, target: string, spec: record]: nothing -> list<any> {
    if $step.file == null { return [] }
    let g = (open $step.file)
    $g.runs | each {|r|
        let req = (gauge run-request $step.file $r ($g | get -o identity))
        let classed = ($doc.runs | where {|x| $x.label == $step.label and $x.run == $r.run } | get -o 0)
        let id = (identity-summary $req)
        let dir = (dir-of $step.file $r)
        let bundle = (if $dir == null { null } else { $dir | path join "bundle" })
        {
            step: $step.label, run: $r.run, seed: ($r | get -o seed),
            kind: ($classed | get -o kind), selection: $req.selection, cadence: $req.cadence, workers: $req.workers, grain: $req.grain,
            standing: ($classed | get -o standing | default "unclassified"), reasons: ($classed | get -o reasons | default []),
            probed: $req.probed, dir: $dir, bundle: (if $bundle != null and ($bundle | path type) == "dir" { $bundle } else { null }),
            identity: $id, agreement: (agreement-of $id $candidate $target $spec),
            measured: ($r | get -o measured), cpu: ($r | get -o cpu),
        }
    }
}

# The bench run against the candidate's bench file: every step of the
# file run, each with the file's own words, none it does not hold, and
# each done; every disagreement named.
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

# A case's expected runs: every step's runs as its words ask them, the
# bench run's words where the step ran and the candidate's bench file's
# where it did not; each found among the runs or missing, and a found run
# played at another seed than its step asks named.
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

# A run named for reading.
def run-name [r: record]: nothing -> string {
    $"($r.step) run ($r.run)"
}

# Why a control's runs leave it unmet, each named: an expected run
# missing, a run not valid, and a run whose identity is not the
# candidate's on the target (agreement-of).
def control-problems [runs: list<any>, missing: list<any>, target: string]: nothing -> list<string> {
    let absent = ($missing | each {|m| $"($m.step) run ($m.run) is missing" })
    let unfit = ($runs | where standing != "valid" | each {|r| $"(run-name $r) stands ($r.standing): ($r.reasons | str join '; ')" })
    let foreign = ($runs | where {|r| not ($r.agreement | is-empty) } | each {|r| $"(run-name $r) is not the candidate's run on ($target): ($r.agreement | str join '; ')" })
    $absent ++ $unfit ++ $foreign
}

# The shim control's reading (ProbeRuns' observer protocol): its probed
# arm the runs whose identity names the shim, its plain arm the others,
# each run valid and the candidate's; the shim's effect on every measure
# over those runs (observer.nu); met once every expected run is there,
# valid, and the candidate's (control-problems), admissible once every
# effect is within its noise.
def shim-reading [runs: list<any>, missing: list<any>, target: string]: nothing -> record {
    let fit = ($runs | where {|r| $r.standing == "valid" and ($r.agreement | is-empty) })
    let arm = {|probed: bool| $fit | where probed == $probed | each {|r| { name: (run-name $r), whole: $r.measured.whole } } }
    let effect = (observer shim-effect (do $arm true) (do $arm false))
    let problems = ((control-problems $runs $missing $target) ++ $effect.problems)
    { met: ($problems | is-empty), admissible: $effect.admissible, measures: $effect.measures, problems: $problems }
}

# The worker scaling control's reading: its forced arm the runs whose
# identity asks a count of workers, its automatic arm the others; per leg
# each run's critical path's and raster's medians, and each hart's
# utilization over each run's whole window; the forced runs judged by
# nothing but this comparison. Met once every expected run is there,
# valid, and the candidate's (control-problems), with its CPU windows
# read, each problem named.
def scaling-reading [runs: list<any>, missing: list<any>, target: string]: nothing -> record {
    let unread = ($runs | where {|r| ($r.cpu | get -o whole.missing | default true) } | each {|r| $"(run-name $r) holds no CPU window over its whole run" })
    let legs = ($runs | each {|r| $r.measured | get -o legs | default [] | get leg } | flatten | uniq)
    let by_leg = ($legs | each {|leg|
        {
            leg: $leg,
            runs: ($runs | each {|r|
                let l = ($r.measured | get -o legs | default [] | where leg == $leg | get -o 0)
                { name: (run-name $r), selection: $r.selection, workers: $r.workers, critical_us: ($l | get -o critical.median), raster_us: ($l | get -o raster.median) }
            }),
        }
    })
    let harts = ($runs | each {|r|
        { name: (run-name $r), selection: $r.selection, workers: $r.workers, interval: ($r.cpu | get -o whole.interval), threads: ($r.cpu | get -o whole.threads | default [] | each {|t| { name: $t.name, utilization: $t.utilization } }) }
    })
    let problems = ((control-problems $runs $missing $target) ++ $unread)
    { met: ($problems | is-empty), legs: $by_leg, harts: $harts, problems: $problems }
}

# The presentation's reading from the probed runs: each run's bundle; the
# shown, superseded, and repeated frames are ProbeRuns' reader's over
# those bundles, admissible as the shim control finds; read once every
# expected run is there, the candidate's, probed, and bundled, each
# problem named.
def bundles-reading [runs: list<any>, missing: list<any>, target: string]: nothing -> record {
    let unbundled = ($runs | where {|r| $r.bundle == null or (not $r.probed) } | each {|r| $"(run-name $r) holds no bundle of the sdl shim's" })
    let problems = ((control-problems $runs $missing $target) ++ $unbundled)
    {
        read: ($problems | is-empty),
        bundles: ($runs | each {|r| { name: (run-name $r), probed: $r.probed, bundle: $r.bundle } }),
        problems: $problems,
        selections: "the shown, superseded, and repeated frames are ProbeRuns' reader's over these bundles",
    }
}

# A diagnostic's readings from the normal play runs (DIAGNOSTICS): per
# route run each leg it names, every leg the run holds where it names
# none, with the fields it reads, and a leg a run lacks named missing.
def diagnostic-reading [d: record, runs: list<any>]: nothing -> record {
    let readings = ($runs | each {|r|
        let held = ($r.measured | get -o legs | default [])
        let wanted = (if ($d.legs | is-empty) { $held | get leg } else { $d.legs })
        $wanted | each {|leg|
            let l = ($held | where leg == $leg | get -o 0)
            if $l == null { { name: (run-name $r), leg: $leg, missing: true, fields: null } } else {
                { name: (run-name $r), leg: $leg, missing: false, fields: ($d.fields | reduce --fold {} {|f, acc| $acc | insert $f ($l | get -o $f) }) }
            }
        }
    } | flatten)
    { case: $d.case, legs: $d.legs, fields: $d.fields, readings: $readings, missing: ($readings | where missing | each {|x| $"($x.name) holds no ($x.leg) leg" }) }
}

# The program's RAM window at the candidate's commit, jab.inc's
# JAB_PROGRAM_SIZE, beside the target's installed RAM (RamTopology): what
# a report states on every target, the RAM past the window held apart.
def ram-of [commit: string, spec: record]: nothing -> record {
    let inc = (jab-file $commit "sdk/src/jab.inc")
    let size = (if $inc == null { null } else { $inc | lines | parse --regex '^\s*\.set JAB_PROGRAM_SIZE, 0x(?P<v>[0-9a-fA-F]+)' | get -o 0.v })
    let window = (if $size == null { null } else { $size | into int --radix 16 })
    { installed_bytes: ($spec.ram | into int), window_bytes: $window }
}

# The watch's record of a bench run, `just watch bench`'s watch.nuon in its
# directory, null where the bench ran unwatched.
def watch-of [bench: path]: nothing -> any {
    let file = ($bench | path join "watch.nuon")
    if ($file | path exists) { open $file } else { null }
}

# One target's qualification record from a bench run (the file header):
# `bench` the run's directory, `candidate` the candidate's record file,
# `target` its named spec.
export def record-of [bench: path, candidate: path, target: string]: nothing -> record {
    let target = ($target | str lowercase)
    if $target not-in $TARGETS { error make { msg: $"($target) is no target of the qualification's matrix, which holds ($TARGETS | str join ', ')" } }
    let bench = ($bench | path expand)
    let listed_file = ($bench | path join "bench.nuon")
    if not ($listed_file | path exists) { error make { msg: $"($bench) holds no bench.nuon, so it is no bench run's directory" } }
    let listed = (open $listed_file)
    let cand = (open --raw $candidate | decode utf-8 | from nuon)
    let spec = (jab spec-row $JAB $target)
    let defined = (jab-file $cand.jab $"game/fps/bench/qual_($target).nuon")
    let definition = (if $defined == null { null } else { $defined | from nuon })
    let doc = (gauge bench-doc $bench)
    let runs = ($doc.steps | each {|s| step-runs $s $doc $cand $target $spec } | flatten)
    let runs = ($runs | each {|r|
        let acceptance = ($CASES | where kind == acceptance | any {|c| $r.step in ($c.steps | get $target) })
        if $acceptance { $r | insert verdict (verdict-of $r) } else { $r }
    })
    let cases = ($CASES | each {|c|
        let labels = ($c.steps | get $target)
        let these = ($runs | where {|r| $r.step in $labels })
        let e = (expected-runs $labels $listed $definition $these)
        let reading = (match $c.reading {
            "verdicts" => ({ passed: ($these | where {|r| $r.verdict.pass } | length), runs: ($these | length) })
            "bundles" => (bundles-reading $these $e.missing $target)
            "shim" => (shim-reading $these $e.missing $target)
            "scaling" => (scaling-reading $these $e.missing $target)
        })
        { case: $c.case, kind: $c.kind, steps: $labels, runs: ($these | each {|r| { step: $r.step, run: $r.run } }), expected: $e.expected, missing: $e.missing, problems: $e.problems, reading: $reading }
    })
    let normal = ($CASES | where case == "normal play" | get 0.steps | get $target)
    let routed = ($runs | where {|r| $r.step in $normal and $r.kind == "route" })
    let head = (head-of $STRESS)
    {
        target: $target,
        written: (date now | format date "%Y-%m-%dT%H:%M:%S%z"),
        readers: { commit: $head.commit, dirty: $head.dirty, sha256: (sha-of $SELF) },
        candidate: ($cand | insert file ($candidate | path expand) | insert sha256 (sha-of $candidate)),
        spec: { name: $spec.name, cores: $spec.cores, ram_bytes: ($spec.ram | into int), display: $spec.display, fps: $spec.fps },
        bench: {
            dir: $bench, bench: ($listed | get -o bench), stamp: ($listed | get -o stamp), state: ($listed | get -o state), file: ($listed | get -o file),
            steps: ($listed.steps | each {|s|
                let file = ($bench | path join $s.label "gauge.nuon")
                { label: $s.label, state: $s.state, exit: ($s | get -o exit), seconds: ($s | get -o seconds), run: $s.run, gauge: (if ($file | path exists) { $file } else { null }), gauge_sha256: (sha-of $file) }
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

# The fields a value lacks of those named, each named where it sits.
def lacking [value: any, keys: list<string>, at: string]: nothing -> list<string> {
    if not (($value | describe) | str starts-with "record") { return [$"($at) is no record"] }
    $keys | where {|k| $k not-in ($value | columns) } | each {|k| $"($at) holds no ($k)" }
}

# A record's schema: the record's fields, each run's, each acceptance
# run's verdict, and each case's; every field it lacks named.
def schema-problems [r: any]: nothing -> list<string> {
    let top = (lacking $r [target written readers candidate spec bench hosts ram runs cases diagnostics limits] "the record")
    if not ($top | is-empty) { return $top }
    let cand = (lacking $r.candidate [tag jab stress image_sha256 elf_sha256 kernel_sha256 assets] "the candidate")
    let runs = ($r.runs | enumerate | each {|e| lacking $e.item [step run seed kind standing reasons identity agreement measured] $"run ($e.index)" } | flatten)
    let verdicts = ($r.runs | where {|x| ($x | describe | str starts-with "record") and ($x | get -o step) != null and ($CASES | where kind == acceptance | any {|c| $x.step in ($c.steps | get -o $r.target | default []) }) } | each {|x|
        if ($x | get -o verdict) == null { [$"($x.step) run ($x.run) holds no verdict"] } else { lacking $x.verdict [pass median_us under over frames problems] $"($x.step) run ($x.run)'s verdict" }
    } | flatten)
    let cases = ($r.cases | enumerate | each {|e| lacking $e.item [case kind steps runs expected missing problems reading] $"case ($e.index)" } | flatten)
    let named = ($CASES | where {|c| $c.case not-in ($r.cases | get -o case | default []) } | each {|c| $"the record holds no case ($c.case)" })
    $cand ++ $runs ++ $verdicts ++ $cases ++ $named
}

# A record held to the schema and the acceptance: its schema
# (schema-problems); the candidate tagged; the readers the candidate's,
# with no changes; the bench the candidate's bench file, every step done;
# every acceptance run present, valid, on the target's named spec, its
# identity the candidate's, and passing, its verdict the one its own
# fields give (verdict-of, agreement-of); every control met; every
# diagnostic's legs read. Every problem named, none for a record that
# holds.
export def check-of [r: any]: nothing -> list<string> {
    let schema = (schema-problems $r)
    if not ($schema | is-empty) { return $schema }
    let cand = $r.candidate
    let spec = (try { jab spec-row $JAB $r.target } catch { null })
    if $r.target not-in $TARGETS or $spec == null { return [$"the record's target, ($r.target), is no target of the qualification's matrix"] }
    let tag = (if $cand.tag == null { ["the candidate is untagged, so no qualification stands on it"] } else { [] })
    let readers = ([
        (if $r.readers.commit != $cand.stress { $"the record was read by the readers at (short $r.readers.commit) where the candidate's are at (short $cand.stress)" })
        (if $r.readers.dirty { "the record was read by readers holding changes" })
    ] | compact)
    let bench = ($r.bench.problems | each {|p| $"the bench: ($p)" })
    let acceptance = ($r.cases | where kind == acceptance | each {|c|
        let missing = ($c.missing | each {|m| $"($c.case): ($m.step) run ($m.run), seed ($m.seed), is missing" })
        let reseeded = ($c.problems | each {|p| $"($c.case): ($p)" })
        let judged = ($c.runs | each {|ref|
            let run = ($r.runs | where {|x| $x.step == $ref.step and $x.run == $ref.run } | get 0)
            let agreement = (agreement-of $run.identity $cand $r.target $spec)
            let again = (verdict-of ($run | update agreement $agreement))
            let name = $"($c.case): (run-name $run), seed ($run.seed)"
            let drift = (if $agreement != $run.agreement or $again.pass != $run.verdict.pass or $again.problems != $run.verdict.problems {
                [$"($name): the record's verdict, (if $run.verdict.pass { 'pass' } else { 'fail' }), is not the one its own fields give, (if $again.pass { 'pass' } else { 'fail' })"]
            } else { [] })
            $drift ++ ($again.problems | each {|p| $"($name): ($p)" })
        } | flatten)
        $missing ++ $reseeded ++ $judged
    } | flatten)
    let controls = ($r.cases | where kind == control | each {|c|
        let reseeded = ($c.problems | each {|p| $"($c.case): ($p)" })
        let unmet = (if $c.reading.met { [] } else { $c.reading.problems | each {|p| $"($c.case): ($p)" } })
        $reseeded ++ $unmet
    } | flatten)
    let presented = ($r.cases | where kind == diagnostic | each {|c|
        let reseeded = ($c.problems | each {|p| $"($c.case): ($p)" })
        let unread = (if $c.reading.read { [] } else { $c.reading.problems | each {|p| $"($c.case): ($p)" } })
        $reseeded ++ $unread
    } | flatten)
    let diagnostics = ($r.diagnostics | each {|d|
        let unread = (if ($d.readings | is-empty) { [$"($d.case): no normal play route run to read"] } else { [] })
        $unread ++ ($d.missing | each {|m| $"($d.case): ($m)" })
    } | flatten)
    $tag ++ $readers ++ $bench ++ $acceptance ++ $controls ++ $presented ++ $diagnostics
}

# A list's median by nearest rank, the gauge's statistics' rule; null for
# no values.
def median-of [values: list<any>]: nothing -> any {
    let v = ($values | compact)
    let n = ($v | length)
    if $n == 0 { return null }
    $v | sort | get ((($n * 0.5) | math ceil) - 1)
}

# Values as milliseconds for a table cell: their median, and with more
# than one their least and greatest in brackets.
def ms-cell [values: list<any>]: nothing -> string {
    let v = ($values | compact)
    if ($v | is-empty) { return "-" }
    if ($v | length) == 1 { return (ms ($v | first)) }
    $"(ms (median-of $v)) \((ms ($v | math min)) to (ms ($v | math max))\)"
}

# The host memory a bench's watch recorded (watch.nuon), as a report's
# line: QEMU's resident memory over the watched runs, the median of each
# run's median and the greatest peak, in MiB; said unrecorded where the
# bench ran unwatched or its reports hold none.
def memory-line [watch: any]: nothing -> string {
    if $watch == null { return "- Host memory was not recorded: the bench ran without a watch." }
    let m = ($watch | get -o watch | default [] | each {|p| $p | get -o watch.memory } | compact)
    if ($m | is-empty) { return "- Host memory was not recorded: the watch's reports hold no resident memory." }
    $"- QEMU's resident memory, read by the watch over ($m | length) runs, was (((median-of ($m | get median)) / 1048576) | math round) MiB at the median and ((($m | get peak | math max) / 1048576) | math round) MiB at the greatest peak."
}

# A table in Markdown from its header and rows of cells.
def md-table [header: list<string>, rows: list<list<string>>]: nothing -> list<string> {
    let line = {|cells: list<string>| $"| ($cells | str join ' | ') |" }
    [(do $line $header) (do $line ($header | each { "---" }))] ++ ($rows | each {|row| do $line $row })
}

# One target's section of the report (report-text), public-production
# writing for TheUser: the verdict, every acceptance run's, the route by
# leg, the tails, the presentation and its shim control, the CPU beside
# the guest's waits, the tile pool, the host, the worker scaling control,
# the problems the check names, and the limits.
def target-section [r: record]: nothing -> list<string> {
    let name = ($r.spec.name | str uppercase)
    let problems = (check-of $r)
    let acceptance = ($r.runs | where {|x| ($x | get -o verdict) != null })
    let passed = ($acceptance | where {|x| $x.verdict.pass } | length)
    let missing = ($r.cases | where kind == acceptance | get missing | flatten | length)
    let verdict = (if ($problems | is-empty) {
        $"The qualification on ($name) passes. Every one of its ($acceptance | length) acceptance runs played under the 15 ms ceiling at its median frame."
    } else {
        $"The qualification on ($name) does not pass. ($passed) of its ($acceptance | length) acceptance runs pass, ($missing) expected runs are missing, and the check names ($problems | length) problems below."
    })
    let runs_table = (md-table ["Run" "Seed" "Median frame" "Frames at or over 15 ms" "Verdict"] ($acceptance | each {|x|
        [(run-name $x) $"($x.seed)" $"(ms $x.verdict.median_us) ms" $"($x.verdict.over | default '-') of ($x.verdict.frames | default '-')" (if $x.verdict.pass { "pass" } else { "fail" })]
    }))
    let normal = ($r.cases | where case == "normal play" | get 0.runs | each {|ref| $r.runs | where {|x| $x.step == $ref.step and $x.run == $ref.run } | get 0 } | where kind == "route")
    let legs = ($normal | each {|x| $x.measured | get -o legs | default [] | get leg } | flatten | uniq)
    let leg_of = {|x: record, leg: string, field: string| $x.measured | get -o legs | default [] | where leg == $leg | get -o 0 | get -o $field }
    let route_table = (md-table ["Leg" "Critical path" "Drawing" "Preparation" "Raster" "Flip" "Presented interval" "Submission age"] ($legs | each {|leg|
        [$leg] ++ ([critical draw preparation raster flip flip_interval submission_age] | each {|f| ms-cell ($normal | each {|x| do $leg_of $x $leg $f | get -o median }) })
    }))
    let tails_table = (md-table ["Leg" "Frames at or over 15 ms" "95th" "99th" "Greatest"] ($legs | each {|leg|
        let over = ($normal | each {|x| do $leg_of $x $leg "over" } | compact)
        let frames = ($normal | each {|x| do $leg_of $x $leg "frames" } | compact)
        [$leg $"(if ($over | is-empty) { '-' } else { $over | math sum }) of (if ($frames | is-empty) { '-' } else { $frames | math sum })" (ms-cell ($normal | each {|x| do $leg_of $x $leg "critical" | get -o p95 })) (ms-cell ($normal | each {|x| do $leg_of $x $leg "critical" | get -o p99 })) (ms-cell ($normal | each {|x| do $leg_of $x $leg "critical" | get -o max }))]
    }))
    let shim = ($r.cases | where case == "presentation's shim control" | get 0.reading)
    let presentation = ($r.cases | where case == "presentation" | get 0.reading)
    let shim_table = (md-table ["Measure" "Probed" "Plain" "Effect" "Noise" "Within"] ($shim.measures | each {|m|
        [$m.measure (ms $m.probed) (ms $m.plain) (ms $m.effect) (ms $m.noise) (if $m.within { "yes" } else { "no" })]
    }))
    let cpu_names = ($normal | each {|x| $x.cpu | get -o whole.threads | default [] | get name } | flatten | uniq | where {|n| $n =~ 'TCG' })
    let cpu_table = (md-table ["Thread" "Utilization over the whole run"] ($cpu_names | each {|n|
        let u = ($normal | each {|x| $x.cpu | get -o whole.threads | default [] | where name == $n | get -o 0.utilization } | compact)
        [$n (if ($u | is-empty) { "-" } else { $"(median-of $u | math round --precision 2) \(($u | math min | math round --precision 2) to ($u | math max | math round --precision 2)\)" })]
    }))
    let waits = ($normal | each {|x| $x.measured | get -o whole })
    let pool = ($normal | each {|x| $x.measured | get -o whole })
    let scaling = ($r.cases | where case == "worker scaling" | get 0.reading)
    let scaling_table = (md-table ["Leg" "Forced critical path" "Automatic critical path" "Forced raster" "Automatic raster"] ($scaling.legs | each {|l|
        let of = {|selection: string, field: string| $l.runs | where selection == $selection | get $field }
        [$l.leg (ms-cell (do $of "forced" "critical_us")) (ms-cell (do $of "automatic" "critical_us")) (ms-cell (do $of "forced" "raster_us")) (ms-cell (do $of "automatic" "raster_us"))]
    }))
    let host = ($r.hosts.hosts | each {|h| $"($h | get -o name | default 'an unnamed host') ($h | get -o os_version | default ''), ($h | get -o cpu | default 'an unrecorded CPU'), ($h | get -o cores | default '-') cores" })
    let qemus = ($r.hosts.qemus | each {|q| $"($q | get -o version | default 'an unrecorded QEMU') at ($q | get -o binary | default '-'), SHA-256 ($q | get -o sha256 | default 'unrecorded')" })
    let window = (if $r.ram.window_bytes == null { "unread" } else { $"($r.ram.window_bytes / 1048576 | math round) MiB" })
    [
        $"## ($name)"
        ""
        $verdict
        ""
        "### The acceptance runs"
        ""
        $"Each run passes when it stands valid, runs the candidate on ($name), and its critical path's median frame is under 15 ms. Each run is judged on its own."
        ""
    ] ++ $runs_table ++ [
        ""
        "### The route by leg"
        ""
        "Each cell is the median over the normal play runs of each run's median frame, in milliseconds, with the least and the greatest run in brackets."
        ""
    ] ++ $route_table ++ [
        ""
        "### The tails"
        ""
        "The frames at or over 15 ms are summed over the normal play runs. The percentiles are each run's own, as above."
        ""
    ] ++ $tails_table ++ [
        ""
        "### Presentation"
        ""
        $"The probed runs carry ($presentation.bundles | where {|b| $b.bundle != null } | length) of ($presentation.bundles | length) bundles. Their shown, superseded, and repeated frames come from the probe's own reader."
        (if $shim.admissible { "The shim control finds every effect within its noise, so the probed readings stand for the unprobed program." } else { "The shim control does not find every effect within its noise, so the probed readings describe the instrumented runs only." })
        ""
    ] ++ $shim_table ++ [
        ""
        "### CPU and the guest's waits"
        ""
        "Each thread's utilization is its CPU seconds over the readings' interval, from five seconds in to the route's end, as the median over the normal play runs."
        ""
    ] ++ $cpu_table ++ [
        ""
        $"The guest waited in its await (ms-cell ($waits | each {|w| $w | get -o await.median })) ms and before its flips (ms-cell ($waits | each {|w| $w | get -o wait.median })) ms at the median frame."
        ""
        "### The tile pool"
        ""
        $"The pool built (($pool | each {|w| $w | get -o tiles_built } | compact | append 0 | math sum)) tiles and evicted (($pool | each {|w| $w | get -o evicted } | compact | append 0 | math sum)) over the normal play runs. It held at most (($pool | each {|w| $w | get -o slots_used_max } | compact | append 0 | math max)) slots."
        ""
        "### The host"
        ""
    ] ++ ($host | each {|h| $"- ($h)" }) ++ ($qemus | each {|q| $"- ($q)" }) ++ [
        $"- The program's RAM window is ($window) of ($r.spec.ram_bytes / 1073741824 | math round) GiB installed. The RAM past the window is held apart."
        (memory-line $r.watch)
        ""
        "### Worker scaling"
        ""
        "The forced runs are judged by this comparison alone. Each cell is the median over the arm's runs."
        ""
    ] ++ $scaling_table ++ [
        ""
        "### Problems"
        ""
    ] ++ (if ($problems | is-empty) { ["The check names no problem."] } else { $problems | each {|p| $"- ($p)" } }) ++ [
        ""
        "### Limits"
        ""
    ] ++ ($r.limits | each {|l| $"- ($l)" }) ++ [""]
}

# The report for TheUser over the targets' records (Qualification.md's
# reports), public-production writing: the candidate, then a section a
# target in the records' order; with `compared` a comparison gauge.nu's
# compare wrote, its table rendered as the comparison with the first
# baseline.
export def report-text [records: list<record>, compared: any]: nothing -> string {
    let cand = ($records | first | get candidate)
    let head = [
        $"# Jab FPS qualification(if $cand.tag == null { '' } else { $': ($cand.tag)' })"
        ""
        "This report says whether Jab FPS plays every frame of actual play under its 15 ms ceiling on each target. A run passes when its median frame is under 15 ms. Every run is judged on its own."
        ""
        "## The candidate"
        ""
        $"- Tag: ($cand.tag | default 'none, so this is no qualification')."
        $"- jab at ($cand.jab), jab-stress at ($cand.stress)."
        $"- The image's SHA-256 is ($cand.image_sha256). The kernel's is ($cand.kernel_sha256)."
        $"- The asset tree, ($cand.assets.map), has the digest ($cand.assets.digest)."
        $"- The toolchain is ($cand.toolchain.version | default 'unrecorded')."
        ""
    ]
    let comparison = (if $compared == null { [] } else {
        let c = $compared
        [
            "## Compared with the first baseline"
            ""
            $"Each cell is ($c | get -o method.field | default 'the field') by leg at 50 cm, in milliseconds, with half the runs' range in brackets."
            ""
        ] ++ (md-table ["Build" "Leg" "Value"] ($c.table | each {|t| [$"($t.build)" $t.leg (if $t.value_us == null { "-" } else { $"(ms $t.value_us) \((ms $t.half_spread_us)\)" })] })) ++ [""]
    })
    ($head ++ ($records | each {|r| target-section $r } | flatten) ++ $comparison) | str join "\n"
}

# The holds' route: Render Zero's legs in the route's order, every leg
# past the start one placement; a synthetic run's frames a leg; and its
# capture nonce.
const FX_LEGS = [start fight spawn yard up down ramp revisit pressure]
const FX_LEG_FRAMES = 4

# A synthetic route as a route file holds one, the legs a run's
# measurement and its CPU windows read.
def fx-route []: nothing -> record {
    { map: $MAP, end: 20sec, legs: ($FX_LEGS | enumerate | each {|e| { name: $e.item, places: (if $e.index == 0 { [] } else { [{ at: ($e.index * 1sec) }] }), pad: [] } }) }
}

# A synthetic capture's bytes: test.nu's records (fx-bytes), each `pack`
# item the console's answer to a placement, a P's.
def fx-capture [items: list<any>]: nothing -> binary {
    $items | each {|i|
        if $i.kind == "pack" { [0x[0b 00 00 00] 0x[50] (1..59 | each { 0x[00] } | bytes collect)] | bytes collect } else { fx-bytes [$i] }
    } | bytes collect
}

# A synthetic route run's records (fx-items at schema 7, cadence 1), a
# placement answered before the first state of every leg past the start,
# so FX_LEG_FRAMES frames fall in each; drawn by `workers`, the W
# answered when `asked`.
def fx-route-items [workers: int, asked: bool]: nothing -> list<any> {
    let frames = (($FX_LEGS | length) * $FX_LEG_FRAMES)
    let items = (if $asked { fx-items $frames --schema 7 --cadence 1 --workers $workers --asked } else { fx-items $frames --schema 7 --cadence 1 --workers $workers })
    1..<($FX_LEGS | length) | reduce --fold $items {|leg, acc|
        let at = ($acc | enumerate | where {|e| $e.item.kind == "state" and ($e.item | get -o frame) == ($leg * $FX_LEG_FRAMES) } | get 0.index)
        $acc | insert $at { kind: "pack" }
    }
}

# A synthetic capture's every frame at `critical` microseconds, its await
# the rest of the synthetic period, as test.nu's frames keep their sum.
def fx-slow [items: list<any>, critical: int]: nothing -> list<any> {
    fx-set-all $items "frame" { critical: $critical, await: ($FX_PERIOD - $critical) }
}

# A synthetic run's CPU windows over the whole run, each of `harts` vCPU
# threads at half a core.
def fx-cpu [harts: int]: nothing -> record {
    let threads = (0..<$harts | each {|h| { id: $h, name: $"CPU ($h)/TCG", cpu_seconds: 7.5, utilization: 0.5 } })
    { whole: { window: "whole", requested_from: 5.0, requested_to: 20.0, missing: false, from: 5.1, to: 20.1, interval: 15.0, threads: $threads }, legs: [] }
}

# A synthetic candidate, jab's HEAD and this repository's, its build's
# digests the fixtures' own.
def fx-candidate [tag: any]: nothing -> record {
    {
        tag: $tag, written: "the holds'", jab: (head-of $JAB).commit, stress: (head-of $STRESS).commit,
        image_sha256: "fx_image", elf_sha256: "fx_elf", kernel_sha256: "fx_kernel", flags: "--defsym FX=1 riscv64-",
        toolchain: { prefix: "riscv64-", version: "GNU assembler 2.47", tools: {} }, assets: { map: $MAP, digest: "fx_assets" },
    }
}

# A synthetic run's identity as gauge.nu's run writes one: the candidate's
# build on the target's machine at cadence 1, `workers` asked or null for
# the automatic choice at grain 0, `pad` route or host, `shim` the sdl
# shim or "" for a plain run, `changes` merged in last.
def fx-identity [cand: record, target: string, seed: int, workers: any, pad: string, shim: string, changes: record]: nothing -> record {
    let spec = (jab spec-row $JAB $target)
    {
        launched: true,
        workspace: { dir: $JAB, commit: ($cand.jab | str substring 0..<7), dirty: false },
        program: { dir: ($JAB | path join game fps), commit: ($cand.jab | str substring 0..<7), dirty: false, from: "git" },
        build: { tree: "release", set: "", flags: $cand.flags, image: "fps.jab", image_sha256: $cand.image_sha256, elf_sha256: $cand.elf_sha256, kernel: "jab.elf", kernel_sha256: $cand.kernel_sha256, provenance: null },
        assets: { map: $MAP, tree: $MAP, digest: $cand.assets.digest },
        route: null, cap: $spec.fps, machine: (jab machine-of --spec $spec), overrides: [],
        qemu: { binary: "qemu-system-riscv64", version: "QEMU emulator version 11.1.2", sha256: "fx_qemu" },
        host: { os: "linux", name: "the holds' host", os_version: "1", kernel_version: "1", hostname: "fx", cpu: "the holds' CPU", cores: 32, memory: 64GiB },
        toolchain: $cand.toolchain,
        mode: { window: true, sound: "host", pad: $pad, seed: $seed, cadence: 1, workers: $workers, grain: (if $workers == null { null } else { 0 }), end: 20sec, capture: 22sec },
        profile: "paired", capture_nonce: 1, shim: $shim,
    } | merge deep $changes
}

# The steps of a target's bench at the candidate's commit as synthetic
# steps (fx-bench): each step's words and runs as its words ask them, a
# route run's records filling every leg and a play's twenty frames, each
# run's identity the candidate's (fx-identity), probed where its step
# names the shim, its CPU windows where its step asks them.
def fx-steps [cand: record, target: string]: nothing -> list<any> {
    let definition = (jab-file $cand.jab $"game/fps/bench/qual_($target).nuon" | from nuon)
    let harts = (jab spec-row $JAB $target).cores
    $definition.steps | each {|s|
        let e = (expected-of $s.run)
        let forced = (flag-of $s.run "--workers")
        let workers = (if $forced == null { null } else { $forced | into int })
        let probed = ("--sdl-probe" in $s.run)
        let play = ($e.kind == "play")
        {
            label: $s.label, words: $s.run, state: "done",
            runs: ($e.runs | each {|x|
                let items = (if $play { fx-items 30 --schema 7 --cadence 1 } else { fx-route-items ($workers | default 2) ($workers != null) })
                let id = (fx-identity $cand $target $x.seed $workers (if $play { "host" } else { "route" }) (if $probed { "jabshim_sdl" } else { "" }) {})
                { run: $x.run, seed: $x.seed, id: $id, items: $items, cpu: (if "--cpu" in $s.run { fx-cpu $harts } else { null }), bundle: $probed }
            }),
        }
    }
}

# A synthetic bench run at `home` (the holds'): bench.nuon listing every
# step with its words and state; each step with runs its directory holding
# its report, gauge.nuon as gauge.nu's run writes one; each run in
# run_<n> beside it with its route, its identity file bound by the
# SHA-256 the run records, and its bundle directory where it was probed;
# each capture measured as measure reads it.
def fx-bench [home: path, target: string, steps: list<any>]: nothing -> string {
    mkdir $home
    {
        bench: $"game/fps/qual_($target)", summary: "the holds'", tree: "release", stamp: "20261017-000000", started: "2026-10-17T00:00:00", file: "the holds'",
        steps: ($steps | each {|s| { label: $s.label, attend: null, run: $s.words, state: $s.state, exit: (if $s.state == "done" { 0 } else { 1 }), seconds: 1.0 } }),
        report: 0, state: "done",
    } | to nuon --indent 2 | save --raw -f ($home | path join "bench.nuon")
    for s in ($steps | where {|x| not ($x.runs | is-empty) }) {
        let dir = ($home | path join $s.label)
        mkdir $dir
        let made = ($s.runs | each {|x|
            let run_dir = ($dir | path join $"run_($x.run)")
            mkdir $run_dir
            let play = ($x.id.mode.pad == "host")
            let id = (if $play { $x.id } else {
                let route_file = ($run_dir | path join "route.nuon")
                fx-route | to nuon | save --raw -f $route_file
                $x.id | upsert route { file: $route_file, sha256: (open --raw $route_file | hash sha256) }
            })
            if $x.bundle { mkdir ($run_dir | path join "bundle") }
            let sha = (gauge write-identity $id $run_dir)
            let m = (gauge measure (fx-capture $x.items) (if $play { [{ name: "play", places: [], pad: [] }] } else { (fx-route).legs }))
            {
                run: { run: $x.run, seed: $x.seed, out: $run_dir, ran: { status: 0, wall_seconds: 30, cpu_seconds: 20 }, measured: ($m | reject rows), identity: $id, corrections: null, identity_sha256: $sha, cpu: $x.cpu },
                rows: ($m.rows | each {|r| $r | insert run $x.run }),
            }
        })
        { label: $s.label, identity: ($made | get 0.run.identity), ceiling_us: $gauge.CEILING_US, runs: ($made | get run), rows: ($made | get rows | flatten) } | to nuon | save --raw -f ($dir | path join "gauge.nuon")
    }
    $home
}

# A synthetic step's run changed: its identity's `changes` merged, its
# seed moved, its records replaced, or its CPU windows dropped.
def fx-alter [steps: list<any>, label: string, run: int, change: closure]: nothing -> list<any> {
    $steps | each {|s| if $s.label != $label { $s } else { $s | update runs ($s.runs | each {|x| if $x.run == $run { do $change $x } else { $x } }) } }
}

# Assert that exactly one of the problems holds the text.
def named-once [problems: list<string>, text: string, why: string]: nothing -> nothing {
    let hits = ($problems | where {|p| $p | str contains $text })
    assert equal ($hits | length) 1 $"($why): one problem holds '($text)', of ($problems | to nuon)"
}

# The holds: the record, the check, and the report over synthetic bench
# runs written under `scratch`, which starts empty. Each target's bench
# whole, every run valid and the candidate's, holds with no problem, its
# shim control met and admissible, its scaling control met, every
# diagnostic read; a faulty bench on 1KA1 names each of its faults once: a
# missing run, a run at the ceiling, an invalid run, a foreign image, a run
# on another spec in the shim control, a step run with other words, a
# step never run with its runs missing, a run played at another seed, a
# run with no CPU window, and the probed arm slower past its noise, which
# leaves the control met and the presentation inadmissible; and records
# altered after their reading: an untagged candidate, other or changed
# readers, a verdict edited against its own fields, and a record lacking a
# field. The report renders both kinds.
export def holds [scratch: path]: nothing -> nothing {
    let scratch = ($scratch | path expand)
    if ($scratch | path exists) { jab retire $scratch (jab target-root $JAB) }
    mkdir $scratch
    let cand = (fx-candidate "qual/0")
    let cand_file = ($scratch | path join "candidate.nuon")
    $cand | to nuon --indent 2 | save --raw $cand_file
    let clean = {|r: record| $r | update readers { commit: $cand.stress, dirty: false, sha256: $r.readers.sha256 } }
    mut passing = []
    for target in $TARGETS {
        let bench = (fx-bench ($scratch | path join $"whole_($target)") $target (fx-steps $cand $target))
        let watched = [{ step: "auto_1", n: 1, watch: { memory: { median: 1073741824, peak: 2147483648, samples: 30 } } } { step: "auto_1", n: 2, watch: { memory: { median: 1048576000, peak: 1610612736, samples: 30 } } }]
        { bench: $"game/fps/qual_($target)", watch: $watched } | to nuon | save --raw -f ($bench | path join "watch.nuon")
        let r = (do $clean (record-of $bench $cand_file $target))
        let problems = (check-of $r)
        assert equal $problems [] $"the whole ($target) bench holds: ($problems | to nuon)"
        assert equal ($r.runs | length) 31 $"the whole ($target) bench reads 31 runs"
        let shim = ($r.cases | where case == "presentation's shim control" | get 0.reading)
        assert ($shim.met and $shim.admissible) $"($target)'s shim control is met and admissible: ($shim.problems | to nuon)"
        assert (($r.cases | where case == "worker scaling" | get 0.reading.met)) $"($target)'s scaling control is met"
        assert equal ($r.diagnostics | get missing | flatten) [] $"every diagnostic of ($target) reads its legs"
        $passing = ($passing | append $r)
    }
    # the faulty bench, each fault in its own step and run
    let base = (fx-steps $cand "1ka1")
    let other = (jab machine-of --spec (jab spec-row $JAB "1kb1"))
    let faulty = ($base
        | each {|s| if $s.label == "auto_1" { $s | update runs ($s.runs | where run != 2) } else { $s } }
        | fx-alter $in "auto_2" 2 {|x| $x | update items (fx-slow $x.items 15000) }
        | fx-alter $in "auto_2" 3 {|x| $x | update items (fx-set $x.items "frame" 5 { status: 3 }) }
        | fx-alter $in "free" 1 {|x| $x | update id ($x.id | merge deep { build: { image_sha256: "fx_other_image" } }) }
        | fx-alter $in "auto_3" 1 {|x| $x | update id ($x.id | update machine $other) }
        | each {|s| if $s.label == "auto_4" { $s | update words ($s.words | where {|w| $w != "--host" }) } else { $s } }
        | where label != "forced1_2"
        | fx-alter $in "auto_5" 1 {|x| $x | update seed 9 | update id ($x.id | update mode.seed 9) }
        | fx-alter $in "auto_6" 3 {|x| $x | update cpu null }
        | fx-alter $in "probed_1" 1 {|x| $x | update items (fx-slow $x.items 2500) }
        | fx-alter $in "probed_1" 2 {|x| $x | update items (fx-slow $x.items 2500) }
        | fx-alter $in "probed_1" 3 {|x| $x | update items (fx-slow $x.items 2500) }
        | fx-alter $in "probed_2" 1 {|x| $x | update items (fx-slow $x.items 2500) }
        | fx-alter $in "probed_2" 2 {|x| $x | update items (fx-slow $x.items 2500) }
        | fx-alter $in "probed_2" 3 {|x| $x | update items (fx-slow $x.items 2500) })
    let fr = (do $clean (record-of (fx-bench ($scratch | path join "faulty") "1ka1" $faulty) $cand_file "1ka1"))
    let found = (check-of $fr)
    named-once $found "normal play: auto_1 run 2, seed 2, is missing" "a missing run"
    named-once $found "normal play: auto_2 run 2, seed 2: its critical path's median, 15.0 ms, is at or over the 15 ms ceiling" "a run at the ceiling"
    named-once $found "normal play: auto_2 run 3, seed 1: it stands invalid" "an invalid run"
    named-once $found "free play: free run 1, seed 1: its image's SHA-256 is fx_other_image where the candidate's is fx_image" "a foreign image"
    named-once $found "presentation's shim control: auto_3 run 1 is not the candidate's run on 1ka1: it was launched as 1kb1, not the target 1ka1" "a run on another spec"
    named-once $found "the bench: step auto_4 ran test/gauge.nu run --tree release --runs 3 --spec 1ka1 where the candidate's bench runs" "a step run with other words"
    named-once $found "the bench: step forced1_2 of the candidate's bench was not run" "a step never run"
    for n in [1 2 3] { named-once $found $"worker scaling: forced1_2 run ($n) is missing" "a never-run step's runs" }
    named-once $found "worker scaling: auto_5 run 1 played seed 9 where its step asks 1" "a run at another seed"
    named-once $found "worker scaling: auto_6 run 3 holds no CPU window over its whole run" "a run with no CPU window"
    let shim = ($fr.cases | where case == "presentation's shim control" | get 0.reading)
    assert ($shim.measures | where measure == "critical path median" | get 0.within | $in == false) "the probed arm slower past its noise is no effect within it"
    assert (not $shim.admissible) "the probed arm slower past its noise leaves the presentation inadmissible"
    assert equal ($found | length) 12 $"the faulty bench names its twelve faults and no more: ($found | to nuon)"
    # records altered after their reading
    let whole = ($passing | first)
    named-once (check-of ($whole | update candidate.tag null)) "the candidate is untagged" "an untagged candidate"
    named-once (check-of ($whole | update readers.commit "0000000000")) "the record was read by the readers at 0000000000" "other readers"
    named-once (check-of ($whole | update readers.dirty true)) "the record was read by readers holding changes" "changed readers"
    let at = ($fr.runs | enumerate | where {|e| $e.item.step == "auto_2" and $e.item.run == 2 } | get 0.index)
    let edited = ($fr | update runs ($fr.runs | update $at ($fr.runs | get $at | update verdict.pass true)))
    named-once (check-of $edited) "normal play: auto_2 run 2, seed 2: the record's verdict, pass, is not the one its own fields give, fail" "a verdict edited against its fields"
    named-once (check-of ($whole | reject cases)) "the record holds no cases" "a record lacking a field"
    # the report over both kinds
    let text = (report-text [$whole $fr] null | lines)
    assert ("The qualification on 1KA1 passes. Every one of its 7 acceptance runs played under the 15 ms ceiling at its median frame." in $text) $"the whole record's report says it passes: ($text | first 40 | str join (char nl))"
    assert ($text | any {|l| $l starts-with "The qualification on 1KA1 does not pass." }) "the faulty record's report says it does not pass"
    assert ($text | any {|l| $l | str contains "| auto_2 run 2 | 2 | 15.0 ms | 36 of 36 | fail |" }) $"the faulty report's run table names the run at the ceiling: ($text | where {|l| $l starts-with '| auto_2' })"
    assert ("- QEMU's resident memory, read by the watch over 2 runs, was 1000 MiB at the median and 2048 MiB at the greatest peak." in $text) "the watched bench's report states its host memory"
    assert ("- Host memory was not recorded: the bench ran without a watch." in $text) "the unwatched bench's report says it holds no host memory"
    report-text $passing null | save --raw -f ($scratch | path join "whole.md")
    print $"qualification: holds, ($scratch)"
}

def main [] {
    print "nu qualification.nu candidate <out.nuon> [--tag qual/<n>]"
    print "nu qualification.nu record <bench run> <candidate.nuon> <target> <out dir>"
    print "nu qualification.nu check <qualification.nuon>"
    print "nu qualification.nu report <qualification.nuon>... <out.md> [--compared <compare.nuon>]"
    print "nu qualification.nu holds <scratch>"
}

# The candidate's record at its freeze (candidate-of), written to `out`.
def "main candidate" [out: path, --tag: string = ""] {
    let c = (candidate-of $tag)
    $c | to nuon --indent 2 | save --raw $out
    print $"qualification: the candidate ($c.tag | default 'untagged') at jab (short $c.jab), jab-stress (short $c.stress), image ($c.image_sha256); ($out)"
}

# A target's record (record-of), written as qualification.nuon in `out`,
# its check's problems printed after it.
def "main record" [bench: path, candidate: path, target: string, out: path] {
    mkdir $out
    let r = (record-of $bench $candidate $target)
    let file = ($out | path join $RECORD)
    $r | to nuon --indent 1 | save --raw $file
    let problems = (check-of $r)
    print $"qualification: ($r.target), ($r.runs | length) runs, ($problems | length) problems the check names; ($file)"
}

# A record held to the schema and the acceptance (check-of): every problem
# printed, and an error naming their count when there is one.
def "main check" [record: path] {
    let problems = (check-of (open $record))
    for p in $problems { print $"qualification: ($p)" }
    if not ($problems | is-empty) { error make { msg: $"($record): ($problems | length) problems" } }
    print $"qualification: ($record) holds"
}

# The holds (holds) under `scratch`.
def "main holds" [scratch: path] {
    holds $scratch
}

# The report over records (report-text), the last path its Markdown file.
def "main report" [...paths: path, --compared: string = ""] {
    if ($paths | length) < 2 { error make { msg: "report takes one record or more, then the report's file" } }
    let out = ($paths | last)
    let records = ($paths | drop 1 | each {|p| open $p })
    let c = (if $compared == "" { null } else { open $compared })
    report-text $records $c | save --raw -f $out
    print $"qualification: ($out)"
}
