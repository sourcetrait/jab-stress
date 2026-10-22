use (path self ../../../../../../jab/nu/mod/sdl)
use (path self ../paired)

# A slow stretch's least host flip interval, 1.5 periods in milliseconds
const STRETCH_MS = 25.0

# The least flips a slow stretch holds
const STRETCH_FLIPS = 5

# Uploads closer than this to the flip before join it, sdl report's grouping
const JOIN_S = 0.005

# The box series' controls: each an arm against another, its runs by their
# labels less `_<n>`, and the side its measures are read from
export const CONTROLS = [
    [control, first, second, side];
    ["the instrumentation", timing, cadence, paired]
    ["end to end", ordinary, e2e_cadence, host]
    ["the API port", api, noapi, host]
]

# The measures a side reads, each a name and its place in a run's measures
export const MEASURES = {
    paired: [
        [measure, field];
        ["guest presented interval median", guest_median_ms]
        ["guest presented interval 95th", guest_p95_ms]
        ["host flip interval median", host_median_ms]
        ["host flip interval 95th", host_p95_ms]
        ["slow stretches", stretches]
        ["shown share", shown_share]
    ]
    host: [
        [measure, field];
        ["host flip interval median", host_median_ms]
        ["host flip interval 95th", host_p95_ms]
        ["slow stretches", stretches]
        ["shown share", shown_share]
    ]
}

# A run's arm, its label less a trailing `_<n>`
def arm-of [label: string]: nothing -> string {
    $label | str replace --regex '_[0-9]+$' ""
}

# A list's nearest-rank quantile, null for no values
def rank [values: list<number>, q: float]: nothing -> any {
    let n = ($values | length)
    if $n == 0 { return null }
    let at = ((($n * $q) | math ceil | into int) - 1)
    $values | sort | get ([$at 0] | math max)
}

# A run's flips on the host from its shim's log as sdl report groups its
# uploads, each flip's first and last upload; the intervals between their
# starts in ms, the slow stretches by STRETCH_MS and STRETCH_FLIPS, and the
# share shown: a render shows the last flip landed since the render before,
# so the flips shown are the renders that found at least one, as ProbeRuns'
# selection reads a paired run; sdl report's `shown` counts the renders that
# found exactly one, and is kept beside it as the report's
export def host-side [probe: path]: nothing -> record {
    let log = ($probe | path join "sdl.log")
    let report = (sdl report $log)
    let events = (sdl classify $log | get events)
    let uploads = ($events | where kind == "upload" | get ts)
    let renders = ($events | where kind == "render" | get ts)
    mut starts = []
    mut ends = []
    mut start = -1.0
    mut end = -1.0
    for t in $uploads {
        if $end >= 0.0 and ($t - $end) < $JOIN_S { $end = $t } else {
            if $end >= 0.0 { $starts = ($starts | append $start); $ends = ($ends | append $end) }
            $start = $t
            $end = $t
        }
    }
    if $end >= 0.0 { $starts = ($starts | append $start); $ends = ($ends | append $end) }
    let count = ($ends | length)
    mut shown = 0
    mut next = 0
    for r in $renders {
        mut landed = false
        while $next < $count and ($ends | get $next) <= $r { $landed = true; $next += 1 }
        if $landed { $shown += 1 }
    }
    let intervals = ($starts | window 2 | each {|w| ($w.1 - $w.0) * 1000.0 })
    mut stretches = 0
    mut slow = 0
    for i in $intervals {
        if $i >= $STRETCH_MS { $slow += 1 } else {
            if $slow >= $STRETCH_FLIPS { $stretches += 1 }
            $slow = 0
        }
    }
    if $slow >= $STRETCH_FLIPS { $stretches += 1 }
    {
        flips: $count, renders: ($renders | length), shown: $shown, unshown_at_end: ($count - $next),
        host_median_ms: (rank $intervals 0.5), host_p95_ms: (rank $intervals 0.95),
        stretches: $stretches,
        shown_share: (if $count == 0 { null } else { $shown / $count }),
        report_frames_shown: $report.frames_shown,
    }
}

# A run's measures from its paired reading: the guest's presented interval
# from the receipts, the host's flip interval of the presented flips, the
# slow stretches, the share shown; null where the reading stopped
def paired-side [reading: record]: nothing -> any {
    if not $reading.valid or ($reading | get -o flips) == null { return null }
    {
        guest_median_ms: ($reading.reading.presented_interval | get -o median_ms),
        guest_p95_ms: ($reading.reading.presented_interval | get -o p95_ms),
        host_median_ms: $reading.flips.host_interval.median_ms,
        host_p95_ms: $reading.flips.host_interval.p95_ms,
        stretches: ($reading.stretches | length),
        shown_share: $reading.flips.share_shown,
    }
}

# One run of the series read: its probe's identity, its paired reading where
# its build is CADENCE's, and its host side from its shim's log
def run-of [base: path, label: string, words: list<string>, readings: path]: nothing -> record {
    let probe = ($base | path join $label "probe")
    let identity = (open --raw ($probe | path join "identity.nuon") | decode | from nuon)
    let cadenced = (($identity | get -o cadence | default []) | is-not-empty)
    let paired = (if $cadenced { paired paired-reading $probe } else { null })
    if $paired != null { $paired | to nuon --indent 1 | save --raw -f ($readings | path join $"($label).paired.nuon") }
    let host = (host-side $probe)
    {
        label: $label, arm: (arm-of $label), words: $words,
        image_sha256: ($identity | get -o image.sha256), kernel_sha256: ($identity | get -o kernel.sha256),
        cadence: ($identity | get -o cadence | default []), capture_nonce: ($identity | get -o capture_nonce),
        paired: (if $paired == null { null } else { { valid: $paired.valid, deciding: $paired.deciding, stage: ($paired | get -o stage), faults: $paired.faults, verdict: ($paired | get -o pairing.verdict) } }),
        measures: { paired: (if $paired == null { null } else { paired-side $paired }), host: $host },
    }
}

# Two arms' effect on each measure of a side, each judged against the noise
def control-of [c: record, runs: list<any>]: nothing -> record {
    let firsts = ($runs | where arm == $c.first)
    let seconds = ($runs | where arm == $c.second)
    let empty = ([[$c.first $firsts] [$c.second $seconds]] | where {|a| ($a.1 | is-empty) } | each {|a| $"the ($a.0) arm holds no run" })
    let unread = ($firsts ++ $seconds | where {|r| ($r.measures | get $c.side) == null } | each {|r| $"($r.label) has no ($c.side) reading: (if $r.paired == null { 'no paired reading' } else { $'it stopped at its ($r.paired.stage | default "reading"), ($r.paired.faults | each {|f| $f.rule } | str join ", ")' })" })
    let measures = ($MEASURES | get $c.side | each {|m|
        let of = {|arm: list<any>| $arm | each {|r| $r.measures | get $c.side | get -o $m.field } | compact }
        let a = (do $of $firsts)
        let b = (do $of $seconds)
        let range = {|v: list<any>| if ($v | is-empty) { null } else { ($v | math max) - ($v | math min) } }
        let ranges = ([(do $range $a) (do $range $b)] | compact)
        let first = (rank $a 0.5)
        let second = (rank $b 0.5)
        let effect = (if $first == null or $second == null { null } else { $first - $second })
        let noise = (if ($ranges | length) < 2 { null } else { ($ranges | math max) / 2 })
        { measure: $m.measure, first: $first, second: $second, effect: $effect, noise: $noise, within: ($effect != null and $noise != null and ($effect | math abs) <= $noise), values: { ($c.first): $a, ($c.second): $b } }
    })
    let problems = ($empty ++ $unread)
    { control: $c.control, first: $c.first, second: $c.second, side: $c.side, measures: $measures, within: (($problems | is-empty) and ($measures | all {|m| $m.within })), problems: $problems }
}

# The images each set built, every run of a set one image, held to its expected SHA-256
def images-of [runs: list<any>, expected: record]: nothing -> list<any> {
    $runs | group-by {|r| $r.cadence | str join "," } | transpose set rows | each {|g|
        let shas = ($g.rows | get image_sha256 | uniq)
        let want = ($expected | get -o $g.set)
        {
            set: (if $g.set == "" { "ordinary" } else { $g.set }), runs: ($g.rows | get label), sha256: $shas,
            expected: $want,
            problems: ([
                (if ($shas | length) != 1 { $"its runs built ($shas | length) images" })
                (if $want != null and $shas != [$want] { $"its image is ($shas | str join ', '), the export's ($want)" })
            ] | compact),
        }
    }
}

# The box series read: every run, each control's effects, the oracle, and
# the images, written to `out` with each paired reading beside it
export def main [base: path, out: path, --expected: string = "{}"]: nothing -> nothing {
    let base = ($base | path expand)
    let runs_file = ($base | path join "runs.nuon")
    if not ($runs_file | path exists) { error make { msg: $"($base) holds no runs.nuon, so it is no series' base" } }
    let listed = (open $runs_file)
    let readings = ($out | path expand | path dirname | path join (($out | path parse | get stem) + ".readings"))
    mkdir $readings
    let runs = ($listed | each {|r| run-of $base $r.label $r.words $readings })
    let controls = ($CONTROLS | each {|c| control-of $c $runs })
    let oracle = ($runs | where label == "oracle" | get -o 0)
    let images = (images-of $runs ($expected | from nuon))
    let record = { reader: "walk controls", base: $base, runs: $runs, controls: $controls, oracle: $oracle, images: $images }
    $record | to nuon --indent 1 | save --raw -f $out
    for r in $runs {
        let p = (if $r.paired == null { "host side alone" } else if $r.paired.valid { $"paired, ($r.paired.verdict)" } else { $"paired reading stopped at its ($r.paired.stage | default 'stream')" })
        let h = $r.measures.host
        print $"walk controls: ($r.label), ($p); host flips ($h.host_median_ms | default '-') ms median, ($h.host_p95_ms | default '-') 95th, ($h.stretches) stretches, shown ($h.shown_share | default '-')"
    }
    for c in $controls {
        print $"walk controls: ($c.control), ($c.first) against ($c.second), (if $c.within { 'every effect within its noise' } else { 'an effect past its noise or unread' })"
        for m in $c.measures { print $"  ($m.measure): ($m.first) against ($m.second), effect ($m.effect), noise ($m.noise)(if $m.within { '' } else { ', past' })" }
        for p in $c.problems { print $"  problem: ($p)" }
    }
    for i in $images { print $"walk controls: images of ($i.set): ($i.sha256 | str join ', ')(if ($i.problems | is-empty) { '' } else { $'; ($i.problems | str join "; ")' })" }
}
