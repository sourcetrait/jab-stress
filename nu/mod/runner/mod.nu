use (path self ./gauge_batches)
use (path self ./jab_probes)
use (path self ./recorded)
use (path self ./stress_bin)
use (path self ./walk_battery)

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
        "gauge_batches" => (gauge_batches ready $a)
        "jab_probes" => (jab_probes ready $a)
        "recorded" => (recorded ready $a)
        "stress_bin" => (stress_bin ready $a)
        "walk_battery" => (walk_battery ready $a)
        _ => (error make { msg: $"no harness ($harness)" })
    }
}

# A harness's work by its name
def work-of [harness: string, a: record]: nothing -> record {
    match $harness {
        "gauge_batches" => (gauge_batches $a)
        "jab_probes" => (jab_probes $a)
        "recorded" => (recorded $a)
        "stress_bin" => (stress_bin $a)
        "walk_battery" => (walk_battery $a)
        _ => (error make { msg: $"no harness ($harness)" })
    }
}
