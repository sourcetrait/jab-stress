use (path self ../matrix)

# What a qualification cannot claim, every target section's last
const LIMITS = [
    "The physical display is not qualified. TheUser's eye is a qualitative reading and never a measured 60 frames a second."
    "A thread's CPU comes from its host's counters, hundredths of a second read every 100 ms, so only an interval of seconds resolves. One less a thread's utilization is everything it did not run, descheduling included, and is never the guest's idle time; the guest's own waits come from its records."
    "Upload and render selection come from the probed runs alone. They stand for the unprobed program's presentation only where the shim control finds every effect within its noise."
    "A release run carries no sound counters. The audio's evidence comes from separate debug runs, labelled diagnostic."
    "The audio's counters show no exhaustion of the guest's queue to the device, observed after each service's drain, which is not output underrun past QEMU's backend. Its 50 ms windows are a coarse continuity check a shorter gap passes, read only where the sound was recorded; a run on live audio reads the driver's counters alone."
]

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

# A sentence's first letter capitalized and a full stop after it
def sentence [s: string]: nothing -> string {
    $"($s | str capitalize)."
}

# The guest clock's ticks in milliseconds to a hundredth, a dash for none
def tick-ms [ticks: any]: nothing -> string {
    if $ticks == null { "-" } else { $"(($ticks / 10000.0) | math round --precision 2) ms" }
}

# The guest's presentation for each acceptance run, from the record's receipts
def guest-section [guest: any]: nothing -> list<string> {
    let intro = [
        ""
        "### The guest's presentation"
        ""
    ]
    if $guest == null { return ($intro ++ ["The record holds no reading of the guest's presentation."]) }
    let tolerances = ($guest.runs | each {|g| $g.tolerances | get eps } | flatten | uniq | sort --reverse)
    let count = {|g: record, eps: int, field: string|
        let v = ($g.tolerances | where eps == $eps | get -o 0 | get -o $field)
        if $v == null { "-" } else { $"($v)" }
    }
    let header = (["Run" "Case" "Qualifying waits"] ++ ($tolerances | each {|e| $"Late at (tick-ms $e)" }) ++ ["Greatest delay"] ++ ($tolerances | each {|e| $"K violations at (tick-ms $e)" }) ++ ["Catch-ups"])
    let rows = ($guest.runs | each {|g|
        [$g.name $g.case (if $g.qualifying_waits == null { "-" } else { $"($g.qualifying_waits)" })] ++ ($tolerances | each {|e| do $count $g $e "late_wakes" }) ++ [(tick-ms $g.greatest_delay_ticks)] ++ ($tolerances | each {|e| do $count $g $e "k_violations" }) ++ [(if $g.catch_ups == null { "-" } else { $"($g.catch_ups)" })]
    })
    let rule = (if $guest.frame_eps != null {
        $"The kernel's frame rule allows (tick-ms $guest.frame_eps), and the gauge reads its own tolerance beside it."
    } else if ($tolerances | is-empty) {
        "Neither the candidate's kernel nor the runs' measurements name a tolerance, so the waits and the catch-ups are read, and no late wake or K violation is counted."
    } else { "The candidate's kernel names no frame rule tolerance, so only the gauge's own is read." })
    let unread = ($guest.runs | where {|g| not $g.available } | each {|g| $"- ($g.name)'s receipts could not be read: ($g.reason)." })
    let untolerated = (if ($tolerances | is-empty) { [] } else {
        $guest.runs | where {|g| $g.available and ($g.tolerances | is-empty) } | each {|g|
            $"- ($g.name)'s measurement names no tolerance, so its waits and catch-ups are read and no late wake or K violation is counted."
        }
    })
    let unperiodic = ($guest.runs | where {|g| ($g | get -o period_unread) != null } | each {|g|
        $"- ($g.name)'s K violations and catch-ups are not counted: ($g.period_unread)."
    })
    let notes = ($unread ++ $untolerated ++ $unperiodic)
    $intro ++ [
        $"Each acceptance run's receipts record when the guest accepted each frame. A wait is late when its frame was accepted at least a tolerance past the tick it waited for. ($rule) A K violation is a frame accepted sooner after an earlier one than the frame rule allows, and a catch-up is a frame accepted less than half a period after the one before. These counts come from the guest's own records. They do not measure the host's scheduler or the display, and they are a diagnostic, never a verdict."
        ""
    ] ++ (md-table $header $rows) ++ (if ($notes | is-empty) { [] } else { [""] ++ $notes })
}

# One target's section of the report, from its check and the record it derived
def target-section [c: record]: nothing -> list<string> {
    let r = (open $c.record)
    let name = ($r.spec.name | str uppercase)
    let problems = $c.problems
    let acceptance = ($r.runs | where {|x| ($x | get -o verdict) != null })
    let passed = ($acceptance | where {|x| $x.verdict.pass } | length)
    let verdict = $"On ($name), (sentence $c.verdicts.final.verdict)"
    let subset = $"Its bench carries the preparation subset, ($c.verdicts.subset.rows | length) of the ($c.ledger | length) obligations: (sentence $c.verdicts.subset.verdict) ($passed) of its ($acceptance | length) acceptance runs pass."
    let ledger_table = (md-table ["Obligation" "Kind" "State" "Ground"] ($c.ledger | each {|x|
        let ground = (match $x.state {
            "met" => ($x.evidence | str join ", ")
            "failed" => ($x.problems | str join "; ")
            _ => $x.why
        })
        [$x.row $x.kind $x.state (if $ground == "" { "-" } else { $ground })]
    }))
    let history = ($c.history | each {|h| $"- The record's ($h.item) reads ($h.stored | to nuon), and derived again from its inputs ($h.derived | to nuon)." })
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
    let service_case = ($r.cases | where case == "service active" | get -o 0)
    let service_section = (if $service_case == null or ($service_case | get -o reading) == null { [] } else {
        let rows = ($service_case.reading.windows | each {|w|
            [$w.name $"($w.offered | default '-')" (if $w.per_frame == null { "-" } else { $"($w.per_frame | math round --precision 2)" }) $"($w.dropped | default '-')" $"($w.skipped | default '-')" (if $w.apply_median_us == null { "-" } else { $"($w.apply_median_us) us" }) (if $w.age_median_us == null { "-" } else { $"($w.age_median_us) us" }) $"(matrix ms $w.median_us) ms"]
        })
        [
            ""
            "### The service active"
            ""
            "These runs play the factory route while a synthetic service sends two messages a frame from a hart of its own. The game applies the messages at the start of each frame, inside the 15 ms. A run counts only when every message is accounted for and no frame's messages were skipped."
            ""
        ] ++ (md-table ["Run" "Messages offered" "Offered a frame" "Dropped" "Frames skipped" "Apply time at the median" "Oldest message's age at the median" "Median frame"] $rows)
    })
    let refusal_case = ($r.cases | where case == "feature unavailable" | get -o 0)
    let refusal_section = (if $refusal_case == null or ($refusal_case | get -o reading) == null { [] } else {
        let held = (if $refusal_case.reading.met { "The refusal held, and play went on untouched." } else { "The refusal did not hold as it should. The problems below say why." })
        let rows = ($refusal_case.reading.runs | each {|x|
            let refused = ($x.refusals | default [] | each {|v| $v | into string } | str join ", ")
            [$x.name (if $refused == "" { "-" } else { $refused }) $"($x.running | default '-')" $"(matrix ms $x.median_us) ms"]
        })
        [
            ""
            "### The feature unavailable"
            ""
            $"On ($name) the game asks for the synthetic service, and its own check refuses it before asking the kernel. Giving the service a hart would leave the graphics fewer harts than the game reserves for them. ($held)"
            ""
        ] ++ (md-table ["Run" "Refusal code" "Frames with the service running" "Median frame"] $rows)
    })
    let audio_case = ($r.cases | where case == "audio" | get -o 0)
    let audio_section = (if $audio_case == null or ($audio_case | get -o reading) == null { [] } else {
        let rows = ($audio_case.reading.runs | each {|x|
            let a = $x.reading
            if $a == null { [$x.name "-" "-" "-" "-" "-"] } else {
                [
                    $x.name
                    (if $a.pad == null { "-" } else { $"($a.pad.taken) of ($a.sent)" })
                    (if $a.pad == null { "-" } else { $"($a.pad.dropped)" })
                    (if $a.sound == null { "-" } else { $"($a.sound.exhausted)" })
                    $"($a.queue_full)"
                    (if $a.windows == null { "not recorded" } else if ($a.windows.quiet | is-empty) { "every window heard" } else { $"($a.windows.quiet | length) quiet windows" })
                ]
            }
        })
        [
            ""
            "### Audio"
            ""
            "These runs use a debug build, because only a debug build counts the sound driver's work. Each plays ten seconds with a table of pad reports. On a host with a sound output the sound plays live. On a host with none it is recorded, and only a recording shows whether the sound ran without gaps. They are a diagnostic, never an acceptance run."
            ""
        ] ++ (md-table ["Run" "Pad events taken" "Pad events dropped" "Times the sound queue ran empty" "Pad reports QEMU dropped" "Continuity"] $rows)
    })
    let host = ($r.hosts.hosts | each {|h| $"($h | get -o name | default 'an unnamed host') ($h | get -o os_version | default ''), ($h | get -o cpu | default 'an unrecorded CPU'), ($h | get -o cores | default '-') cores" })
    let qemus = ($r.hosts.qemus | each {|q| $"($q | get -o version | default 'an unrecorded QEMU') at ($q | get -o binary | default '-'), SHA-256 ($q | get -o sha256 | default 'unrecorded')" })
    let window = (if $r.ram.window_bytes == null { "unread" } else { $"($r.ram.window_bytes / 1048576 | math round) MiB" })
    [
        $"## ($name)"
        ""
        $verdict
        $subset
        $bench_line
        ""
        "### The obligations"
        ""
        "Every final obligation of the qualification on this target is a row: met on its evidence, failed with its problems, pending on its dependency, or not applicable for its reason. Qualification passes only when every row is met or not applicable."
        ""
    ] ++ $ledger_table ++ [
        ""
        "### The acceptance runs"
        ""
        $"Each run passes when it stands valid, runs the candidate on ($name), and its critical path's median frame is under 15 ms. Each run is judged on its own."
        ""
    ] ++ $runs_table ++ (guest-section ($r | get -o guest_presentation)) ++ [
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
    ] ++ $scaling_table ++ $service_section ++ $refusal_section ++ $audio_section ++ [
        ""
        "### Problems"
        ""
    ] ++ (if ($problems | is-empty) { ["The check names no problem."] } else { $problems | each {|p| $"- ($p | str capitalize)." } }) ++ [
        ""
        "### The record's own answers"
        ""
        "The check derives the record again from its reopened inputs under the current readers. Where the record's stored answer differs, both are shown; the stored one is its own reader's answer and fails nothing."
        ""
    ] ++ (if ($history | is-empty) { ["Every stored answer is the one derived again."] } else { $history }) ++ [
        ""
        "### Limits"
        ""
    ] ++ ($LIMITS | each {|l| $"- ($l)" }) ++ [""]
}

# The report over the targets' checks, a section a target
export def report-text [checks: list<record>, compared: any]: nothing -> string {
    let cand = (open ($checks | first | get record) | get candidate)
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
    ] ++ ($cand | get -o builds | default {} | transpose name build | each {|x| $"- The ($x.name) build, the same source with ($x.build.set) set, has the image ($x.build.image_sha256) and the kernel ($x.build.kernel_sha256)." }) ++ [
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
    ($head ++ ($checks | each {|c| target-section $c } | flatten) ++ $comparison) | str join "\n"
}

# The report over checks, the last path its Markdown file
export def main [...paths: path, --compared: string = ""]: nothing -> nothing {
    if ($paths | length) < 2 { error make { msg: "report takes one check or more, then the report's file" } }
    let out = ($paths | last)
    let checks = ($paths | drop 1 | each {|p| open $p })
    let unchecked = ($checks | where {|c| ($c | get -o record) == null })
    if not ($unchecked | is-empty) { error make { msg: "a check that derived no record cannot be reported: its schema or target was refused" } }
    let c = (if $compared == "" { null } else { open $compared })
    report-text $checks $c | save --raw -f $out
    print $"qualification: ($out)"
}
