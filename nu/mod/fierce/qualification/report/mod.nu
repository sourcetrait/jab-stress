use (path self ../check)
use (path self ../matrix)

# A list's median by nearest rank, null for no values
def median-of [values: list<any>]: nothing -> any {
    let v = ($values | compact)
    let n = ($v | length)
    if $n == 0 { return null }
    $v | sort | get ((($n * 0.5) | math ceil) - 1)
}

# Values as a table cell in milliseconds: median, then least to greatest
def ms-cell [values: list<any>]: nothing -> string {
    let v = ($values | compact)
    if ($v | is-empty) { return "-" }
    if ($v | length) == 1 { return (matrix ms ($v | first)) }
    $"(matrix ms (median-of $v)) \((matrix ms ($v | math min)) to (matrix ms ($v | math max))\)"
}

# The host memory a bench's watch recorded, as a report's line
def memory-line [watch: any]: nothing -> string {
    if $watch == null { return "- Host memory was not recorded: the bench ran without a watch." }
    let m = ($watch | get -o watch | default [] | each {|p| $p | get -o watch.memory } | compact)
    if ($m | is-empty) { return "- Host memory was not recorded: the watch's reports hold no resident memory." }
    $"- QEMU's resident memory, read by the watch over ($m | length) runs, was (((median-of ($m | get median)) / 1048576) | math round) MiB at the median and ((($m | get peak | math max) / 1048576) | math round) MiB at the greatest peak."
}

# A table in Markdown from its header and rows of cells
def md-table [header: list<string>, rows: list<list<string>>]: nothing -> list<string> {
    let line = {|cells: list<string>| $"| ($cells | str join ' | ') |" }
    [(do $line $header) (do $line ($header | each { "---" }))] ++ ($rows | each {|row| do $line $row })
}

# One target's section of the report
def target-section [r: record]: nothing -> list<string> {
    let name = ($r.spec.name | str uppercase)
    let problems = (check check-of $r)
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
        [(matrix run-name $x) $"($x.seed)" $"(matrix ms $x.verdict.median_us) ms" $"($x.verdict.over | default '-') of ($x.verdict.frames | default '-')" (if $x.verdict.pass { "pass" } else { "fail" })]
    }))
    let normal = ($r.cases | where case == "normal play" | get 0.runs | each {|ref| $r.runs | where {|x| $x.step == $ref.step and $x.run == $ref.run } | get 0 } | where kind == "route")
    let legs = ($normal | each {|x| $x.measured | get -o legs | default [] | get leg } | flatten | uniq)
    let leg_of = {|x: record, leg: string, field: string| $x.measured | get -o legs | default [] | where leg == $leg | get -o 0 | get -o $field }
    let route_table = (md-table ["Leg" "Critical path" "Drawing" "Preparation" "Raster" "Flip" "Acceptance interval" "Completion interval" "Submission age"] ($legs | each {|leg|
        [$leg] ++ ([critical draw preparation raster flip acceptance_interval completion_interval submission_age] | each {|f| ms-cell ($normal | each {|x| do $leg_of $x $leg $f | get -o median }) })
    }))
    let tails_table = (md-table ["Leg" "Frames at or over 15 ms" "95th" "99th" "Greatest"] ($legs | each {|leg|
        let over = ($normal | each {|x| do $leg_of $x $leg "over" } | compact)
        let frames = ($normal | each {|x| do $leg_of $x $leg "frames" } | compact)
        [$leg $"(if ($over | is-empty) { '-' } else { $over | math sum }) of (if ($frames | is-empty) { '-' } else { $frames | math sum })" (ms-cell ($normal | each {|x| do $leg_of $x $leg "critical" | get -o p95 })) (ms-cell ($normal | each {|x| do $leg_of $x $leg "critical" | get -o p99 })) (ms-cell ($normal | each {|x| do $leg_of $x $leg "critical" | get -o max }))]
    }))
    let shim = ($r.cases | where case == "presentation's shim control" | get 0.reading)
    let presentation = ($r.cases | where case == "presentation" | get 0.reading)
    let bundles = ($presentation | get -o bundles | default [])
    let probed = ($presentation | get -o runs | default [])
    let read_runs = ($probed | where {|x| ($x | get -o stage) == null })
    let at = {|v: any| if $v == null { "-" } else { $"(matrix ms $v) ms" } }
    let share = {|v: any| if $v == null { "-" } else { $"($v * 100 | math round --precision 1) percent" } }
    let presentation_table = (md-table ["Run" "Pairing" "Frames" "Shown" "Superseded" "Repeats" "Age" "Presented interval"] ($read_runs | each {|x|
        let w = $x.whole
        [$"($x.label) run ($x.run)" $x.pairing.verdict $"($w.frames)" $"($w.shown), (do $share $w.share_shown)" $"($w.superseded), at most ($w.longest_superseded) in a row" $"($w.repeated)" (do $at $w.age.median) (do $at $w.presented_interval.median)]
    }))
    let cadence_lines = ($presentation | get -o cadences | default [] | each {|c|
        let w = $c.whole
        let repeats = (if $w.repeated == 0 { "No render showed a frame a second time." } else { $"($w.repeated) renders showed a frame again. No frame was shown again more than ($w.longest_repeat) times." })
        $"At cadence ($c.cadence), over ($c.runs | length) runs, ($w.shown) of ($w.frames) frames were shown, which is (do $share $w.share_shown). ($w.superseded) frames were superseded, at most ($w.longest_superseded) in a row. ($repeats) A shown frame reached the window (do $at $w.age.median) after its upload at the median."
    })
    let unread_count = (($probed | length) - ($read_runs | length))
    let unread_line = (if $unread_count == 0 { [] } else { [$"($unread_count) of the ($probed | length) probed runs could not be read whole. The problems below say why."] })
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
        $"The probed runs carry ($bundles | where {|b| $b.bundle != null } | length) of ($bundles | length) bundles. ProbeRuns' reader pairs each run's uploads with the guest's presents and reads which frames the window drew. A frame is shown when a render draws it. It is superseded when a later frame replaces it before any render draws it. A frame's age is the time from its upload to the first render that shows it."
        ""
    ] ++ $presentation_table ++ [""] ++ $cadence_lines ++ $unread_line ++ [
        ""
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

# The report over the targets' records, a section a target
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
        ] ++ (md-table ["Build" "Leg" "Value"] ($c.table | each {|t| [$"($t.build)" $t.leg (if $t.value_us == null { "-" } else { $"(matrix ms $t.value_us) \((matrix ms $t.half_spread_us)\)" })] })) ++ [""]
    })
    ($head ++ ($records | each {|r| target-section $r } | flatten) ++ $comparison) | str join "\n"
}

# The report over records, the last path its Markdown file
export def main [...paths: path, --compared: string = ""] {
    if ($paths | length) < 2 { error make { msg: "report takes one record or more, then the report's file" } }
    let out = ($paths | last)
    let records = ($paths | drop 1 | each {|p| open $p })
    let c = (if $compared == "" { null } else { open $compared })
    report-text $records $c | save --raw -f $out
    print $"qualification: ($out)"
}
