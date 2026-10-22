use (path self ../../../../../../jab/nu/mod/sdl)
use (path self ../../../selection)
use (path self ../reading) [guest-of ms rank spread spread-us]
use (path self ../stream) [HZ fault flags-of header-nonce]

# A slow stretch's least host flip interval, 1.5 periods in microseconds
const STRETCH_US = 25000

# The least presented flips a slow stretch holds
const STRETCH_FLIPS = 5

# A measure's least rise over the run's steady median, a quarter period in ticks
const RISE = 41666

# The guest's phases a stretch is located by
const PHASES = [work wait call]

# Each presented flip's guest figures beside what the host's renders chose
def flip-rows [frames: list<record>, presented: list<record>, chosen: list<any>, timing: bool]: nothing -> list<any> {
    if ($presented | length) != ($chosen | length) { error make { msg: $"the selection holds ($chosen | length) pairs for ($presented | length) presents" } }
    $presented | zip $chosen | enumerate | each {|e|
        let f = $e.item.0
        let s = $e.item.1
        if $s.ordinal != $f.ordinal { error make { msg: $"the selection's pair ($e.index) is ordinal ($s.ordinal), its present's ($f.ordinal)" } }
        let before = (if $e.index == 0 { null } else { $presented | get ($e.index - 1) })
        {
            frame: $f.frame, ordinal: $f.ordinal, start: $f.start,
            frame_interval: (if $f.frame == 0 { null } else { $f.start - ($frames | get ($f.frame - 1) | get start) }),
            presented_interval: (if $before == null { null } else { $f.s - $before.s }),
            work: (if $timing { $f.work_end - $f.start } else { null }),
            wait: (if $timing { $f.wait_end - $f.wait_start } else { null }),
            call: (if $timing { $f.call_end - $f.call_start } else { null }),
            upload_interval_us: $s.upload_interval_us, age_us: $s.age_us, shown_interval_us: $s.shown_interval_us,
            renders: $s.renders, repeats: $s.repeats, shown: $s.shown, superseded: $s.superseded, unshown: $s.unshown,
        }
    }
}

# The presented flips' host side: what the renders chose, the intervals, the age
def flips-summary [rows: list<any>, renders: int]: nothing -> record {
    let n = ($rows | length)
    let shown = ($rows | where shown | length)
    {
        presents: $n, renders: $renders, shown: $shown,
        superseded: ($rows | where superseded | length),
        repeated: (if $n == 0 { 0 } else { $rows | get repeats | math sum }),
        unshown_at_end: ($rows | where unshown | length),
        share_shown: (if $n == 0 { null } else { $shown / $n }),
        host_interval: (spread-us ($rows | get upload_interval_us | compact)),
        presented_interval: (spread ($rows | get presented_interval | compact)),
        age: (spread-us ($rows | get age_us | compact)),
        shown_interval: (spread-us ($rows | get shown_interval_us | compact)),
    }
}

# A stretch's figure for one measure against the run's steady flips
def against-steady [name: string, stretch: list<any>, steady: list<any>]: nothing -> record {
    let mine = ($stretch | get $name | compact)
    let base = ($steady | get $name | compact)
    let median = (rank $mine 0.5)
    let middle = (rank $base 0.5)
    let rise = (if $median == null or $middle == null { null } else { $median - $middle })
    {
        name: $name, median_ms: (ms $median), steady_median_ms: (ms $middle), steady_p95_ms: (ms (rank $base 0.95)),
        rise_ms: (ms $rise), risen: ($rise != null and $rise >= $RISE),
    }
}

# The slow stretches, each set against the run's steady flips and located
def stretches-of [rows: list<any>, timing: bool]: nothing -> list<any> {
    mut runs = []
    mut current = []
    for r in ($rows | enumerate) {
        let slow = ($r.item.upload_interval_us != null and $r.item.upload_interval_us >= $STRETCH_US)
        if $slow {
            $current = ($current | append $r.index)
        } else {
            if ($current | length) >= $STRETCH_FLIPS { $runs = ($runs | append [$current]) }
            $current = []
        }
    }
    if ($current | length) >= $STRETCH_FLIPS { $runs = ($runs | append [$current]) }
    let inside = ($runs | reduce --fold [] {|x, acc| $acc ++ $x })
    let steady = ($rows | enumerate | where {|r| $r.index not-in $inside } | get item)
    $runs | each {|run|
        let mine = ($run | each {|i| $rows | get $i })
        let frame = (against-steady frame_interval $mine $steady)
        let phases = (if $timing { $PHASES | each {|k| against-steady $k $mine $steady } } else { null })
        let risen = (if $timing { $phases | where risen | get name } else { [] })
        let located = (if not $timing { null } else if not ($risen | is-empty) {
            $risen | each {|p| { work: "the work", wait: "the wait", call: "the flip call" } | get $p }
        } else if not $frame.risen { ["delivery past the guest"] } else { ["the frame, its rise spread across its phases"] })
        {
            first: { frame: ($mine | first | get frame), ordinal: ($mine | first | get ordinal) },
            last: { frame: ($mine | last | get frame), ordinal: ($mine | last | get ordinal) },
            flips: ($mine | length),
            at_s: (($mine | first | get start) / $HZ),
            host_interval: (spread-us ($mine | get upload_interval_us | compact)),
            presented_interval: (spread ($mine | get presented_interval | compact)),
            frame_interval: $frame,
            phases: $phases,
            located: $located,
        }
    }
}

# A probed run read paired: bundle, stream, pairing, renders, and stretches
export def paired-reading [probe: path, --eps: int = 10000, --replay: path]: nothing -> record {
    let dir = ($probe | path expand)
    let bundle = ($dir | path join "bundle")
    let identity = (open --raw ($bundle | path join "identity.nuon") | into binary | decode | from nuon)
    let bytes = (open --raw ($bundle | path join "api.out") | into binary)
    let g = (guest-of $bytes $identity $eps false $replay)
    let base = ($g.result | merge { mode: "paired", guest_only: false, stage: null, capture: null, pairing: null, flips: null, stretches: null })
    if not $g.result.valid { return ($base | merge { stage: "stream" }) }
    let checked = (try { sdl bundle-check $bundle --guest {|api| header-nonce (open --raw $api | into binary) } } catch {|e| { refusal: $e.msg } })
    if ($checked | get -o refusal) != null {
        return ($base | merge { stage: "capture", valid: false, deciding: false, faults: ($g.result.faults ++ [(fault "the capture" 1 [$checked.refusal])]) })
    }
    let capture = ($checked | reject events)
    let timing = (flags-of $g.stream.header.flags).timing
    let origin = $g.stream.header.origin
    let frames = $g.stream.frames
    let presented = ($frames | where {|f| $f.issued == 1 and $f.status == 0 })
    let flips = ($presented | each {|f| { status: 0, ordinal: $f.ordinal, lo: ($origin + (if $timing { $f.call_start } else { $f.start })), hi: ($origin + $f.call_end) } })
    let pair = (sdl pair $checked.events $flips)
    let pairing = {
        verdict: $pair.verdict, refusals: $pair.refusals, bound: (if $timing { "recorded" } else { "frame" }),
        bracket: $pair.bracket, shifts: $pair.shifts, window: $pair.window, fit: $pair.fit,
        stalls: (if $timing { { calls: $pair.stalls, frame: [] } } else { { calls: [], frame: $pair.stalls } }),
    }
    if not $pair.ok {
        let refused = (fault "the pairing" ($pair.refusals | length) ($pair.refusals | each {|r| $"($r.refusal): ($r.count)" }))
        return ($base | merge { stage: "pairing", valid: false, deciding: false, capture: $capture, pairing: $pairing, faults: ($g.result.faults ++ [$refused]) })
    }
    let chosen = (selection $checked.events $pair.pairs)
    let rows = (flip-rows $frames $presented $chosen.frames $timing)
    $base | merge { capture: $capture, pairing: $pairing, flips: (flips-summary $rows $chosen.renders), stretches: (stretches-of $rows $timing) }
}
