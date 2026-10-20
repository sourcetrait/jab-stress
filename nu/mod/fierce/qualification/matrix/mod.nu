use (path self ../../../../../../jab/nu/mod/bench)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge/report) [CEILING_US]
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge/audio) [QUEUE_FULL]

# jab, checked out beside the workbench
export const JAB = (path self ../../../../../../jab | path expand)

# The workbench's own checkout
export const STRESS = (path self ../../../../.. | path expand)

# The qualification's targets, each a named spec
export const TARGETS = ["1ka1" "1kb1"]

# The map every run plays
export const MAP = "render_0"

# A target's record's file in its directory
export const RECORD = "qualification.nuon"

# The matrix's cases: kind, reading, each target's steps, and why a target
# holding none of a case's steps leaves it not applicable
export const CASES = [
    [case, kind, reading, steps, absent];
    ["normal play", acceptance, verdicts, {"1ka1": [auto_1 auto_2], "1kb1": [auto_1 auto_2]}, {}]
    ["free play", acceptance, verdicts, {"1ka1": [free], "1kb1": [free]}, {}]
    ["presentation", diagnostic, presentation, {"1ka1": [probed_1 probed_2], "1kb1": [probed_1 probed_2]}, {}]
    ["presentation's shim control", control, shim, {"1ka1": [probed_1 auto_3 auto_4 probed_2], "1kb1": [probed_1 auto_3 auto_4 probed_2]}, {}]
    ["worker scaling", control, scaling, {"1ka1": [forced1_1 auto_5 auto_6 forced1_2], "1kb1": [forced2_1 auto_5 auto_6 forced2_2]}, {}]
    ["service active", acceptance, service, {"1ka1": [], "1kb1": [service_1 service_2]}, {"1ka1": "1KA1's three harts hold the main hart and the two reserved graphics harts, so no feature is admitted there (TheUser's spec model); its refusal is the feature unavailable's row"}]
    ["feature unavailable", control, refusal, {"1ka1": [unavailable], "1kb1": []}, {"1kb1": "1KB1's seven harts admit the feature, so its refusal is 1KA1's row"}]
    ["audio", control, audio, {"1ka1": [audio], "1kb1": [audio]}, {}]
]

# The QEMU words the audio's step carries, its dropped reports' trace
export const AUDIO_WORDS = ["-trace" $QUEUE_FULL]

# The service's start refused under the floor, the take's GFX_FLOOR
export const GFX_FLOOR = -1

# The diagnostics read from the normal play runs, their legs and fields
export const DIAGNOSTICS = [
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

# Every final obligation past the bench's cases: its kind, and by target its dependency or its reason
export const OBLIGATIONS = [
    [row, kind, state, why];
    ["the parity", correctness, {"1ka1": pending, "1kb1": pending}, {"1ka1": "the parity tool on both maps' still copies at the freeze", "1kb1": "the parity tool on both maps' still copies at the freeze"}]
    ["the OWNER captures", correctness, {"1ka1": pending, "1kb1": pending}, {"1ka1": "the OWNER captures at the freeze", "1kb1": "the OWNER captures at the freeze"}]
    ["the fps suite on the target", correctness, {"1ka1": pending, "1kb1": pending}, {"1ka1": "the fps suite on 1KA1 at the freeze", "1kb1": "the fps suite on 1KB1 at the freeze"}]
    ["the freeze's fps suite", freeze, {"1ka1": pending, "1kb1": pending}, {"1ka1": "the fps suite at the tagged candidate", "1kb1": "the fps suite at the tagged candidate"}]
    ["the freeze's root suite", freeze, {"1ka1": pending, "1kb1": pending}, {"1ka1": "the root suite at the tagged candidate", "1kb1": "the root suite at the tagged candidate"}]
    ["TheUser's Linux host", host, {"1ka1": pending, "1kb1": pending}, {"1ka1": "his host's bench on 1KA1, its probed runs bundled (U1)", "1kb1": "his host's bench on 1KB1, its probed runs bundled (U1)"}]
    ["the Windows runs", host, {"1ka1": pending, "1kb1": pending}, {"1ka1": "WindowsHost, PadWindows, and his host (U4)", "1kb1": "WindowsHost, PadWindows, and his host (U4)"}]
    ["the reports and the evidence package", reports, {"1ka1": pending, "1kb1": pending}, {"1ka1": "the reports from the final records and the evidence package landed (EvidenceRetention)", "1kb1": "the reports from the final records and the evidence package landed (EvidenceRetention)"}]
]

# The bench's verb in a step's words, play, run, or audio, whatever script names it
export def step-verb [words: list<string>]: nothing -> any {
    $words | skip 1 | where {|w| $w in [play run audio] } | get -o 0
}

# The named build a step's words run, its first `{build:<name>}`, null for the tree's own
export def role-of [words: list<string>]: nothing -> any {
    $words | each {|w| $w | parse --regex '\{build:(?P<name>[a-z][a-z0-9_]*)\}' | each {|p| $p.name } } | flatten | get -o 0
}

# The guest inputs every packaged step takes, by their places in the package
export const PACKAGED = {
    image: "fierce/fierce.jab", kernel: "kernel/jab.elf", assets: "asset/render_0", route: "route/route_render_0.nuon",
}

# The candidate's bench as its package runs it: the preflight, packaged inputs;
# a step naming its image keeps it, a named build's that the package lays
export def packaged-bench [definition: record, target: string]: nothing -> record {
    let at = {|rel: string| $"{package}/($rel)" }
    let images = ["--image" (do $at $PACKAGED.image) "--kernel" (do $at $PACKAGED.kernel)]
    let assets = ["--assets" (do $at $PACKAGED.assets)]
    let route = ["--route" (do $at $PACKAGED.route)]
    let preflight = {
        label: "preflight", gate: true,
        run: ["../../nu/bin/nuance/package.nu" "preflight" "{package}" "--spec" $target "--image" $PACKAGED.image "--kernel" $PACKAGED.kernel "--tree" $PACKAGED.assets "--serial" "fps" "--bench" $"bench/qual_($target).nuon"],
    }
    $definition | upsert build "none" | update steps ([$preflight] ++ ($definition.steps | each {|s|
        let own = ("--image" in $s.run)
        $s | update run ($s.run ++ (if $own { [] } else { $images }) ++ $assets ++ (if (step-verb $s.run) == "run" { $route } else { [] }))
    }))
}

# A bench's definition as a run of it read its words: every `{package}` the
# package's directory and every `{build:<name>}` that build's directory under
# `root`, the bench run's record of where its builds lay
export def resolved-in [definition: record, package: any, root: any]: nothing -> record {
    $definition | update steps ($definition.steps | each {|s|
        let placed = (if $package == null { $s.run } else { $s.run | each {|w| $w | str replace --all "{package}" $package } })
        $s | update run (if $root == null { $placed } else { bench built-words $placed $root })
    })
}

# The value after a flag among a step's words, null where it is absent
export def flag-of [words: list<string>, flag: string]: nothing -> any {
    let at = ($words | enumerate | where item == $flag | get -o 0.index)
    if $at == null { null } else { $words | get -o ($at + 1) }
}

# What a qualification record cannot claim, stated with every reading
export const LIMITS = [
    "The physical display is not qualified. TheUser's eye is a qualitative reading and never a measured 60 frames a second."
    "A thread's CPU comes from its host's counters, hundredths of a second read every 100 ms, so only an interval of seconds resolves. One less a thread's utilization is everything it did not run, descheduling included, and is never the guest's idle time; the guest's own waits come from its records."
    "Upload and render selection come from the probed runs alone. They stand for the unprobed program's presentation only where the shim control finds every effect within its noise."
    "A release run carries no sound counters. The audio's evidence comes from separate debug runs, labelled diagnostic."
    "The audio's counters show no exhaustion of the guest's queue to the device, observed after each service's drain, which is not output underrun past QEMU's backend. Its 50 ms windows are a coarse continuity check a shorter gap passes, read only where the sound was recorded; a run on live audio reads the driver's counters alone."
]

# A file's SHA-256, null where there is none
export def sha-of [file: path]: nothing -> any {
    if ($file | path exists) { open --raw $file | hash sha256 } else { null }
}

# A file of jab's at a commit, its text, null where the commit holds none
export def jab-file [commit: string, file: string]: nothing -> any {
    let shown = (^git -C $JAB show $"($commit):($file)" | complete)
    if $shown.exit_code != 0 { null } else { $shown.stdout }
}

# Milliseconds to a tenth from microseconds, a dash for none
export def ms [us: any]: nothing -> string {
    if $us == null { "-" } else { $"(($us / 1000.0) | math round --precision 1)" }
}

# A commit shortened for reading
export def short [commit: any]: nothing -> string {
    if $commit == null { "none" } else { $commit | str substring 0..<10 }
}

# Whether a commit as an identity records it is the candidate's
def same-commit [recorded: any, candidate: string]: nothing -> bool {
    $recorded != null and ($recorded | str length) >= 7 and ($candidate | str starts-with $recorded)
}

# The build a step's runs are held to: the candidate's release build, or the
# named build its words run, each with its tree and the QEMU words its step carries
export def build-of [candidate: record, role: any, words: list<string>]: nothing -> record {
    let overrides = (if (step-verb $words) == "audio" { $AUDIO_WORDS } else { [] })
    if $role == null {
        return { name: "the candidate's", image_sha256: $candidate.image_sha256, elf_sha256: $candidate.elf_sha256, kernel_sha256: $candidate.kernel_sha256, tree: "release", overrides: $overrides, missing: null }
    }
    let b = ($candidate | get -o builds | default {} | get -o $role)
    if $b == null { return { name: $"the candidate's ($role) build's", image_sha256: null, elf_sha256: null, kernel_sha256: null, tree: null, overrides: $overrides, missing: $"the candidate records no build ($role), which its step runs" } }
    { name: $"the candidate's ($role) build's", image_sha256: $b.image_sha256, elf_sha256: $b.elf_sha256, kernel_sha256: $b.kernel_sha256, tree: $b.tree, overrides: $overrides, missing: null }
}

# Where a run's identity disagrees with its build, the candidate, and the target, named
export def agreement-of [id: record, candidate: record, build: record, target: string, spec: record]: nothing -> list<string> {
    let m = ($id.machine | default {})
    let named = ($m | get -o spec)
    let program = ($id.program | default {})
    let workspace = ($id.workspace | default {})
    let program_commit = ($program | get -o commit)
    let words = ($id.overrides | default [])
    if $build.missing != null { return [$build.missing] }
    [
        (if $id.image_sha256 != $build.image_sha256 { $"its image's SHA-256 is ($id.image_sha256 | default 'unrecorded') where ($build.name) is ($build.image_sha256)" })
        (if $id.elf_sha256 != $build.elf_sha256 { $"its ELF's SHA-256 is ($id.elf_sha256 | default 'unrecorded') where ($build.name) is ($build.elf_sha256)" })
        (if $id.kernel_sha256 != $build.kernel_sha256 { $"its kernel's SHA-256 is ($id.kernel_sha256 | default 'unrecorded') where ($build.name) is ($build.kernel_sha256)" })
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
        (if $words != $build.overrides { $"its launch carried the QEMU words (if ($words | is-empty) { 'none' } else { $words | str join ' ' }) where its step carries (if ($build.overrides | is-empty) { 'none' } else { $build.overrides | str join ' ' })" })
        (if ($m | get -o harts) != $spec.cores { $"its machine has ($m | get -o harts | default 'unrecorded') harts where ($target) has ($spec.cores)" })
        (if ($m | get -o ram_gib) != ($spec.ram / 1GiB | into int) { $"its machine has ($m | get -o ram_gib | default 'unrecorded') GiB where ($target) has ($spec.ram / 1GiB | into int)" })
        (if ($named | get -o display) != $spec.display { $"its display is ($named | get -o display | to nuon) where ($target)'s is ($spec.display | to nuon)" })
        (if $id.cap != $spec.fps { $"its cap is ($id.cap | default 'unrecorded') where ($target)'s frame rate is ($spec.fps)" })
        (if $id.tree != $build.tree { $"its build is the ($id.tree | default 'unrecorded') tree, not ($build.tree)" })
    ] | compact
}

# Whether a value is a finite number, a float judged by its text
def finite [v: any]: nothing -> bool {
    match ($v | describe) {
        "int" => true,
        "float" => (($v | into string) not-in ["inf" "-inf" "NaN"]),
        _ => false,
    }
}

# Where a run's identity and record differ from its step's words, each named
export def conditions-of [id: record, ran: any, words: list<string>]: nothing -> list<string> {
    let verb = (step-verb $words)
    let play = ($verb == "play")
    let audio = ($verb == "audio")
    let host = ($play or ("--host" in $words))
    let forced = (flag-of $words "--workers")
    let workers = (if $forced == null { null } else { $forced | into int })
    let cadence = (if $audio { null } else { flag-of $words "--cadence" | default "1" | into int })
    let probed = ("--sdl-probe" in $words)
    let mode = ($id.mode | default {})
    let pad = (if $play { "host" } else if $audio { "table" } else { "route" })
    let sound = (if $host { "host" } else { "recorded" })
    let quota = (flag-of $words "--service" | default "-1" | into int)
    let service = (if $quota < 0 { null } else { $quota })
    [
        (if ($mode | get -o service) != $service { $"it asked (if ($mode | get -o service) == null { 'no service' } else { $'the service at ($mode.service) a frame' }) where its step asks (if $service == null { 'none' } else { $'($service) a frame' })" })
        (if ($mode | get -o workers) != $workers { $"it asked (if ($mode | get -o workers) == null { 'the automatic workers' } else { $'($mode.workers) workers' }) where its step asks (if $workers == null { 'the automatic ones' } else { $'($workers)' })" })
        (if ($mode | get -o cadence) != $cadence { $"it played cadence ($mode | get -o cadence | default 'unrecorded') where its step asks ($cadence)" })
        (if ($mode | get -o window) != $host { $"its window was (if ($mode | get -o window) == true { 'on' } else { 'off' }) where its step asks it (if $host { 'on' } else { 'off' })" })
        (if ($mode | get -o sound) != $sound { $"its sound was ($mode | get -o sound | default 'unrecorded') where its step asks ($sound)" })
        (if ($mode | get -o pad) != $pad { $"its pad was ($mode | get -o pad | default 'unrecorded') where its step asks ($pad)" })
        (if (($id.shim | default "") != "") != $probed { $"it ran (if $probed { 'without' } else { 'with' }) the sdl probe where its step (if $probed { 'probes' } else { 'probes nothing' })" })
    ] | compact
}

# A tag resolved in jab against the candidate's commit: met, pending, or failed
export def tag-state [tag: any, commit: string]: nothing -> record<state: string, why: string> {
    if $tag == null { return { state: "pending", why: "the candidate carries no qual tag, so no freeze stands" } }
    let named = (^git -C $JAB rev-parse $"($tag)^{commit}" | complete)
    if $named.exit_code != 0 { return { state: "failed", why: $"jab holds no tag ($tag)" } }
    let at = ($named.stdout | str trim)
    if $at != $commit { return { state: "failed", why: $"($tag) names ($at) in jab, where the candidate is ($commit)" } }
    { state: "met", why: $"($tag) names the candidate's commit in jab" }
}

# Why a run cannot certify the steady service load, each named: its capture
# holding the service's records, a start answered, one window closed, no quota
# skipped; a window's own breaks stand in the run's standing
export def service-problems [run: record]: nothing -> list<string> {
    let sv = ($run.measured | get -o service)
    if $sv == null { return ["its capture holds no service record, so its image is no SERVICE build's"] }
    if not $sv.started { return [$"its service never started: (if ($sv.refusals | is-empty) { 'no start answered' } else { $'refused, status ($sv.refusals | each {|v| $v | into string } | str join ', ')' })"] }
    [
        (if ($sv.windows | length) != 1 { $"($sv.windows | length) service windows closed where its route runs one" })
        (if $sv.reduced { $"($sv.skipped) quotas skipped, a reduced load reported at its offered rate and never certifying the steady load" })
    ] | compact
}

# An acceptance run's verdict: valid, its build's, under the ceiling; with
# `--service`, its steady service load admissible as well
export def verdict-of [run: record, --service]: nothing -> record {
    let whole = ($run.measured | get -o whole)
    let median = ($whole | get -o critical.median)
    let under = (if $run.standing == "valid" and (finite $median) { gauge report under-ceiling $median } else { null })
    let problems = ([
        (if $run.standing != "valid" { $"it stands ($run.standing): ($run.reasons | str join '; ')" })
        (if $run.standing == "valid" and not (finite $median) { "it holds no play median, a finite median over a valid play window" })
        ...$run.agreement
        ...($run | get -o conditions | default [])
        ...(if $service { service-problems $run } else { [] })
        (if $under == false { $"its critical path's median, (ms $median) ms, is at or over the ($CEILING_US // 1000) ms ceiling" })
    ] | compact)
    { pass: ($problems | is-empty), median_us: $median, ceiling_us: $CEILING_US, under: $under, over: ($run.measured | get -o over), frames: ($run.measured | get -o frames), problems: $problems }
}

# A run named for reading
export def run-name [r: record]: nothing -> string {
    $"($r.step) run ($r.run)"
}

# A case's problems: its missing and reseeded runs, its verdicts or reading
export def case-problems [r: record, c: record]: nothing -> list<string> {
    let missing = ($c.missing | each {|m| $"($m.step) run ($m.run), seed ($m.seed), is missing" })
    let reseeded = $c.problems
    let judged = (match $c.kind {
        "acceptance" => ($c.runs | each {|ref|
            let run = ($r.runs | where {|x| $x.step == $ref.step and $x.run == $ref.run } | get 0)
            $run.verdict.problems | each {|p| $"(run-name $run), seed ($run.seed): ($p)" }
        } | flatten)
        "control" => (if $c.reading.met { [] } else { $c.reading.problems })
        _ => (if $c.reading.read { [] } else { $c.reading.problems })
    })
    if $c.kind == "acceptance" { $missing ++ $reseeded ++ $judged } else { $reseeded ++ $judged }
}

# A diagnostic's problems: no route run to read, or a leg a run lacks
export def diagnostic-problems [d: record]: nothing -> list<string> {
    let unread = (if ($d.readings | is-empty) { ["no normal play route run to read"] } else { [] })
    $unread ++ $d.missing
}

# Every final obligation on the record's target a row: its state and its ground
export def ledger-of [r: record, tag: record, held: list<string>]: nothing -> list<any> {
    let row = {|name: string, kind: string, carried: bool, problems: list<string>, evidence: list<string>|
        { row: $name, kind: $kind, carried: $carried, state: (if ($problems | is-empty) { "met" } else { "failed" }), evidence: $evidence, why: "", problems: $problems }
    }
    let cases = ($r.cases | each {|c|
        if ($c | get -o applicable | default true) {
            do $row $c.case $c.kind true (case-problems $r $c) ($c.runs | each {|x| $"($x.step) run ($x.run)" })
        } else {
            { row: $c.case, kind: $c.kind, carried: true, state: "not applicable", evidence: [], why: ($c | get -o why | default ""), problems: [] }
        }
    })
    let diagnostics = ($r.diagnostics | each {|d| do $row $d.case "diagnostic" true (diagnostic-problems $d) ($d.readings | each {|x| $x.name } | uniq) })
    let bench = (do $row "the bench held to its definition" "freeze" true $held [$"the bench file at ($r.candidate.jab | str substring 0..<10)"])
    let tagged = { row: "the tagged candidate", kind: "freeze", carried: false, state: $tag.state, evidence: (if $tag.state == "met" { [$r.candidate.tag] } else { [] }), why: (if $tag.state == "met" { "" } else { $tag.why }), problems: (if $tag.state == "failed" { [$tag.why] } else { [] }) }
    let others = ($OBLIGATIONS | each {|o| { row: $o.row, kind: $o.kind, carried: false, state: ($o.state | get $r.target), evidence: [], why: ($o.why | get $r.target), problems: [] } })
    $cases ++ $diagnostics ++ [$bench $tagged] ++ $others
}

# The preparation subset's verdict and the final one, read from a ledger
export def verdicts-of [ledger: list<any>]: nothing -> record {
    let carried = ($ledger | where carried)
    let unmet = ($carried | where {|x| $x.state not-in ["met" "not applicable"] } | get row)
    let failed = ($ledger | where state == "failed" | get row)
    let pending = ($ledger | where state == "pending" | each {|x| { row: $x.row, dependency: $x.why } })
    let subset = (if ($unmet | is-empty) { "the preparation subset passes" } else { $"the preparation subset does not pass: ($unmet | str join ', ')" })
    let final = (if not ($failed | is-empty) {
        $"qualification does not pass: ($failed | str join ', ')"
    } else if not ($pending | is-empty) {
        $"qualification incomplete: ($pending | each {|p| $'($p.row), pending ($p.dependency)' } | str join '; ')"
    } else { "qualification passes" })
    {
        subset: { rows: ($carried | get row), passes: ($unmet | is-empty), verdict: $subset },
        final: { passes: (($failed | is-empty) and ($pending | is-empty)), failed: $failed, pending: $pending, verdict: $final },
    }
}
