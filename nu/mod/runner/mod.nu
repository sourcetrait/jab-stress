use (path self ./cadence_battery)
use (path self ./cadence_image_battery)
use (path self ./captures_base)
use (path self ./captures_compare)
use (path self ./fps_suite)
use (path self ./grain_battery)
use (path self ./jab_do)
use (path self ./jab_programs)
use (path self ./jab_suite)
use (path self ./pixel_identity)
use (path self ./route_battery)
use (path self ./scaling_batteries)
use (path self ./scaling_parity)
use (path self ./scaling_sweep)
use (path self ./smoke)
use (path self ./stress_bin)
use (path self ./tilecensus_reading)
use (path self ./two_build_battery)
use (path self ./worker_battery)

# An error's messages as plain text, each with its wrapped lines, then its help
def said [e: record]: nothing -> string {
    $e.rendered | ansi strip | lines | reduce --fold [] {|l, acc|
        if ($l starts-with "  x ") {
            $acc | append ($l | str substring 4..)
        } else if ($l starts-with "  | ") and ($acc | is-not-empty) {
            $acc | drop 1 | append $"($acc | last) ($l | str substring 4..)"
        } else if ($l starts-with "  help: ") {
            $acc | append ($l | str trim)
        } else {
            $acc
        }
    } | str join "; "
}

# A harness's checks before its launch, as NUON; a refusal on stderr, exit 1
export def ready [harness: string, given: string]: nothing -> string {
    let a = ($given | from nuon)
    try { ready-of $harness $a | to nuon } catch {|e| print -e (said $e); exit 1 }
}

# A harness's work, its result as NUON; a failure on stderr, exit 1
export def work [harness: string, given: string]: nothing -> string {
    let a = ($given | from nuon)
    try { work-of $harness $a | to nuon } catch {|e| print -e (said $e); exit 1 }
}

# A battery run whole here: its ready, then its work, its result as NUON
export def bench [harness: string, given: path, stress: path]: nothing -> string {
    let a = (open $given | upsert stress $stress)
    ready-of $harness $a | ignore
    work-of $harness $a | to nuon
}

# A harness's checks by its name
def ready-of [harness: string, a: record]: nothing -> record {
    match $harness {
        "cadence_battery" => (cadence_battery ready $a)
        "cadence_image_battery" => (cadence_image_battery ready $a)
        "captures_base" => (captures_base ready $a)
        "captures_compare" => (captures_compare ready $a)
        "fps_suite" => (fps_suite ready $a)
        "grain_battery" => (grain_battery ready $a)
        "jab_do" => (jab_do ready $a)
        "jab_programs" => (jab_programs ready $a)
        "jab_suite" => (jab_suite ready $a)
        "pixel_identity" => (pixel_identity ready $a)
        "route_battery" => (route_battery ready $a)
        "scaling_batteries" => (scaling_batteries ready $a)
        "scaling_parity" => (scaling_parity ready $a)
        "scaling_sweep" => (scaling_sweep ready $a)
        "smoke" => (smoke ready $a)
        "stress_bin" => (stress_bin ready $a)
        "tilecensus_reading" => (tilecensus_reading ready $a)
        "two_build_battery" => (two_build_battery ready $a)
        "worker_battery" => (worker_battery ready $a)
        _ => (error make { msg: $"no harness ($harness)" })
    }
}

# A harness's work by its name
def work-of [harness: string, a: record]: nothing -> record {
    match $harness {
        "cadence_battery" => (cadence_battery $a)
        "cadence_image_battery" => (cadence_image_battery $a)
        "captures_base" => (captures_base $a)
        "captures_compare" => (captures_compare $a)
        "fps_suite" => (fps_suite $a)
        "grain_battery" => (grain_battery $a)
        "jab_do" => (jab_do $a)
        "jab_programs" => (jab_programs $a)
        "jab_suite" => (jab_suite $a)
        "pixel_identity" => (pixel_identity $a)
        "route_battery" => (route_battery $a)
        "scaling_batteries" => (scaling_batteries $a)
        "scaling_parity" => (scaling_parity $a)
        "scaling_sweep" => (scaling_sweep $a)
        "smoke" => (smoke $a)
        "stress_bin" => (stress_bin $a)
        "tilecensus_reading" => (tilecensus_reading $a)
        "two_build_battery" => (two_build_battery $a)
        "worker_battery" => (worker_battery $a)
        _ => (error make { msg: $"no harness ($harness)" })
    }
}
