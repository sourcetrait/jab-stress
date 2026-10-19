use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)

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

# The matrix's cases: kind, reading, and each target's steps
export const CASES = [
    [case, kind, reading, steps];
    ["normal play", acceptance, verdicts, {"1ka1": [auto_1 auto_2], "1kb1": [auto_1 auto_2]}]
    ["free play", acceptance, verdicts, {"1ka1": [free], "1kb1": [free]}]
    ["presentation", diagnostic, bundles, {"1ka1": [probed_1 probed_2], "1kb1": [probed_1 probed_2]}]
    ["presentation's shim control", control, shim, {"1ka1": [probed_1 auto_3 auto_4 probed_2], "1kb1": [probed_1 auto_3 auto_4 probed_2]}]
    ["worker scaling", control, scaling, {"1ka1": [forced1_1 auto_5 auto_6 forced1_2], "1kb1": [forced2_1 auto_5 auto_6 forced2_2]}]
]

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

# What a qualification record cannot claim, stated with every reading
export const LIMITS = [
    "The physical display is not qualified. TheUser's eye is a qualitative reading and never a measured 60 frames a second."
    "A thread's CPU comes from its host's counters, hundredths of a second read every 100 ms, so only an interval of seconds resolves. One less a thread's utilization is everything it did not run, descheduling included, and is never the guest's idle time; the guest's own waits come from its records."
    "Upload and render selection come from the probed runs alone. They stand for the unprobed program's presentation only where the shim control finds every effect within its noise."
    "A release run carries no sound counters. The audio's evidence comes from separate debug runs, labelled diagnostic."
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

# Where a run's identity disagrees with the candidate and target, named
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

# An acceptance run's verdict: valid, the candidate's, under the ceiling
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

# A run named for reading
export def run-name [r: record]: nothing -> string {
    $"($r.step) run ($r.run)"
}
