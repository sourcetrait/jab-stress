# qualification.nu: FrameCeiling's Qualification, the closing acceptance
# against actual play on both targets (FrameCeiling/Qualification.md).
# `candidate` builds the release tree and writes the candidate's record at
# its freeze. `record` reads one target's bench run, a run of the game's
# bench/qual_<target>.nuon, through `gauge bench doc` and every run
# through run-request, into the target's qualification record: the
# candidate, the bench against the candidate's bench file, every run with
# its standing, its identity, and that identity's agreement with the
# candidate and the target, each case of the matrix with its runs, every
# acceptance run's verdict, the controls' readings and the diagnostics'
# apart, the host, and the limits stated. `check` holds a record to the
# schema and the acceptance, every problem named. `report` writes the
# document for TheUser, a section a target. Run under the real nu: `nu
# qualification.nu <command> ...` (`fps/just/qualification.just`).
use ../../../jab/nu/mod/spec
use ../../../jab/nu/mod/build
use ../../../jab/nu/mod/identity
use ../../../jab/kit/fierce/nu/mod/gauge
use ./observer.nu

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
# names none, and the fields of a leg's summary (gauge/measure's leg-summary).
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
# tree built at jab's HEAD (`do.nu build`), then jab's commit, its
# checkout's HEAD with no changes, `tag` when given refused unless it
# names that HEAD; this repository's commit, its checkout's HEAD,
# recorded with whether the checkout holds changes and the commit `tag`
# names there, null for none, and never refused; the game's release image,
# its ELF, and the kernel built with it, each by its SHA-256, the image's
# flags free of DEBUG; the toolchain those flags name, each tool the file
# its prefix resolves to with that file's SHA-256 (`gauge identity
# resolved-file`); and Render Zero's asset tree by gauge/identity's digest, the
# tree every run plays.
export def candidate-of [tag: string]: nothing -> record {
    let repos = [[repo, dir]; [jab $JAB] [stress $STRESS]]
    let heads = ($repos | each {|r|
        let h = (head-of $r.dir)
        # this repository's changes and tag recorded, never refused
        if $r.repo == "stress" {
            let named = (if $tag == "" { null } else { ^git -C $r.dir rev-parse $"($tag)^{commit}" | complete })
            let tagged = (if $named == null or $named.exit_code != 0 { null } else { $named.stdout | str trim })
            return { repo: $r.repo, commit: $h.commit, dirty: $h.dirty, tagged: $tagged }
        }
        if $h.dirty { error make { msg: $"($r.dir) holds changes; a candidate is a commit with every file of it committed" } }
        if $tag != "" {
            let named = (^git -C $r.dir rev-parse $"($tag)^{commit}" | complete)
            if $named.exit_code != 0 { error make { msg: $"($r.dir) has no tag ($tag)" } }
            if ($named.stdout | str trim) != $h.commit { error make { msg: $"($tag) names ($named.stdout | str trim) in ($r.dir), whose HEAD is ($h.commit)" } }
        }
        { repo: $r.repo, commit: $h.commit }
    })
    let game = ($JAB | path join kit fierce)
    let built = (^nu (if ($JAB | path join nu bin do.nu | path exists) { $JAB | path join nu bin do.nu } else { $JAB | path join sdk nu jab.nu }) build $game | complete)
    if $built.exit_code != 0 { error make { msg: $"the release build of ($game): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
    let out = (build program-out $game release)
    let image = ($out | path join fierce.jab)
    let elf = ($out | path join fierce.elf)
    let kernel = (build program-kernel $game release)
    for f in [$image $elf $kernel] { if not ($f | path exists) { error make { msg: $"the release build left no ($f)" } } }
    let flags = (open --raw ($out | path join flags) | decode | lines | first)
    if ($flags =~ '--defsym DEBUG=') { error make { msg: $"the release image's flags define DEBUG: ($flags)" } }
    let prefix = ($flags | split row " " | last)
    {
        tag: (if $tag == "" { null } else { $tag }),
        written: (date now | format date "%Y-%m-%dT%H:%M:%S%z"),
        jab: ($heads | where repo == jab | get 0.commit),
        stress: ($heads | where repo == stress | get 0.commit),
        stress_checkout: ($heads | where repo == stress | get 0 | select dirty tagged),
        image_sha256: (sha-of $image),
        elf_sha256: (sha-of $elf),
        kernel_sha256: (sha-of $kernel),
        flags: $flags,
        toolchain: {
            prefix: $prefix,
            version: (try { ^$"($prefix)as" --version | complete | get stdout | lines | get -o 0 } catch { null }),
            tools: { as: (gauge identity resolved-file $"($prefix)as"), ld: (gauge identity resolved-file $"($prefix)ld"), objcopy: (gauge identity resolved-file $"($prefix)objcopy") },
        },
        assets: { map: $MAP, digest: (gauge identity tree-digest (build program-shard $game asset | path join $MAP)) },
    }
}

# The value after a flag among a step's words, null where it is absent.
def flag-of [words: list<string>, flag: string]: nothing -> any {
    let at = ($words | enumerate | where item == $flag | get -o 0.index)
    if $at == null { null } else { $words | get -o ($at + 1) }
}

# The runs a step's words ask for, the gauge's defaults where they name
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
# the ceiling by `gauge report under-ceiling`, the one rule; every problem
# named; the median and the tail beside it.
export def verdict-of [run: record]: nothing -> record {
    let whole = ($run.measured | get -o whole)
    let median = ($whole | get -o critical.median)
    let under = (if $run.standing == "valid" and $median != null { gauge report under-ceiling $median } else { null })
    let problems = ([
        (if $run.standing != "valid" { $"it stands ($run.standing): ($run.reasons | str join '; ')" })
        ...$run.agreement
        (if $under == false { $"its critical path's median, (ms $median) ms, is at or over the ($gauge.CEILING_US // 1000) ms ceiling" })
    ] | compact)
    { pass: ($problems | is-empty), median_us: $median, ceiling_us: $gauge.CEILING_US, under: $under, over: ($run.measured | get -o over), frames: ($run.measured | get -o frames), problems: $problems }
}

# A run's directory as its report's run-dirs find it, null where none is.
def dir-of [file: path, r: record]: nothing -> any {
    gauge identity dirs $file $r | where {|d| ($d | path type) == "dir" } | get -o 0
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
    let spec = (spec row $JAB $target)
    let defined = (jab-file $cand.jab $"kit/fierce/bench/qual_($target).nuon"
        | default (jab-file $cand.jab $"game/fps/bench/qual_($target).nuon"))
    let definition = (if $defined == null { null } else { $defined | from nuon })
    let doc = (gauge bench doc $bench)
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
    {
        target: $target,
        written: (date now | format date "%Y-%m-%dT%H:%M:%S%z"),
        readers: (identity reader [$STRESS $JAB] --launches),
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
# (schema-problems); the candidate tagged; the bench the candidate's bench
# file, every step done; every acceptance run present, valid, on the
# target's named spec, its identity the candidate's, and passing, its
# verdict the one its own fields give (verdict-of, agreement-of); every
# control met; every diagnostic's legs read. The readers that wrote it
# are its provenance alone. Every problem named, none for a record that
# holds.
export def check-of [r: any]: nothing -> list<string> {
    let schema = (schema-problems $r)
    if not ($schema | is-empty) { return $schema }
    let cand = $r.candidate
    let spec = (try { spec row $JAB $r.target } catch { null })
    if $r.target not-in $TARGETS or $spec == null { return [$"the record's target, ($r.target), is no target of the qualification's matrix"] }
    let tag = (if $cand.tag == null { ["the candidate is untagged, so no qualification stands on it"] } else { [] })
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
    $tag ++ $bench ++ $acceptance ++ $controls ++ $presented ++ $diagnostics
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
    let done = ($r.bench.steps | where state == "done" | length)
    let bench_line = $"The bench ($r.bench.bench | default 'with no name') ran at ($r.bench.stamp | default 'an unrecorded time'). ($done) of its ($r.bench.steps | length) steps ran to their end."
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
    let us = {|v: any| if $v == null { "-" } else { $"($v | math round)" } }
    let shim_table = (md-table ["Measure" "Probed (us)" "Plain (us)" "Effect (us)" "Noise (us)" "Within"] ($shim.measures | each {|m|
        [$m.measure (do $us $m.probed) (do $us $m.plain) (do $us $m.effect) (do $us $m.noise) (if $m.within { "yes" } else { "no" })]
    }))
    let outcomes = ($normal | each {|x| $x.measured | get -o outcomes } | compact)
    let event_count = {|event: string| $outcomes | each {|o| $o | get -o androids | default [] | where event == $event | get -o 0.count | default 0 } | append 0 | math sum }
    let fight_line = $"Over the normal play runs the androids were roused (do $event_count roused) times and destroyed (do $event_count destroyed) times, the player was struck ($outcomes | each {|o| $o | get -o struck | default 0 } | append 0 | math sum) times, and ($outcomes | each {|o| $o | get -o pickups | default 0 } | append 0 | math sum) magazines were picked up."
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
        $bench_line
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
        $fight_line
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
    ] ++ (if ($problems | is-empty) { ["The check names no problem."] } else { $problems | each {|p| $"- ($p | str capitalize)." } }) ++ [
        ""
        "### Limits"
        ""
    ] ++ ($r.limits | each {|l| $"- ($l)" }) ++ [""]
}

# The report for TheUser over the targets' records (Qualification.md's
# reports), public-production writing: the candidate, then a section a
# target in the records' order; with `compared` a comparison `gauge
# compare` wrote, its table rendered as the comparison with the first
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

def main [] {
    print "nu qualification.nu candidate <out.nuon> [--tag qual/<n>]"
    print "nu qualification.nu record <bench run> <candidate.nuon> <target> <out dir>"
    print "nu qualification.nu check <qualification.nuon>"
    print "nu qualification.nu report <qualification.nuon>... <out.md> [--compared <compare.nuon>]"
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

# The report over records (report-text), the last path its Markdown file.
def "main report" [...paths: path, --compared: string = ""] {
    if ($paths | length) < 2 { error make { msg: "report takes one record or more, then the report's file" } }
    let out = ($paths | last)
    let records = ($paths | drop 1 | each {|p| open $p })
    let c = (if $compared == "" { null } else { open $compared })
    report-text $records $c | save --raw -f $out
    print $"qualification: ($out)"
}
