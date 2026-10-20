use (path self ../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../jab/nu/mod/sdl)
use (path self ../../../../../jab/nu/mod/present)
use (path self ../observer)
use (path self ../../selection)

# The guest's clock, ticks a second
const HZ = 10000000

# K's tolerance in ticks, walk's reader's default
const EPS = 10000

# The bounds that are a call's own; an outer one holds more than its call
const CALLS = ["recorded" "derived"]

# The longest run of trues in a list, 0 for none
def longest [flags: list<bool>]: nothing -> int {
    mut best = 0
    mut run = 0
    for f in $flags {
        if $f {
            $run += 1
            if $run > $best { $best = $run }
        } else {
            $run = 0
        }
    }
    $best
}

# The capture nonce the guest echoed in its load record, null for none
def guest-nonce [api: path]: nothing -> any {
    (gauge stream (open --raw $api | into binary)).loads | get -o 0.nonce
}

# Why a run's capture is not read, each named, none where it stands
def capture-problems [m: record, asked: any]: nothing -> list<string> {
    [
        (if not $m.complete { $"incomplete: ($m.problems | first 3 | str join '; ')" })
        (if $m.complete and (not $m.valid) { $"invalid: ($m.invalid | first 3 | str join '; ')" })
        (if not $m.seeded { "unseeded" } else if $m.late_seed { "seeded after its first frame" })
        (if $asked == null {
            "its identity asks no cadence"
        } else if not $m.cadence_set {
            if $m.late_cadence { "its cadence answered after its first frame" } else { "its cadence never answered" }
        } else if $m.cadences != [$asked] {
            $"its frames played cadences ($m.cadences | str join ', ') where its identity asks ($asked)"
        })
        (if not $m.nonce_set {
            if $m.late_nonce { "its capture nonce answered after its first frame" } else { "its capture nonce never answered" }
        })
    ] | compact
}

# The pairing's stalls by the bounds they stand on, a call's or an outer one
def stalls-of [stalls: list<any>, flips: list<any>]: nothing -> record<calls: list<any>, outer: list<any>> {
    let bounded = ($stalls | each {|s| $s | insert bound ($flips | where {|f| $f.status == 0 and $f.ordinal == $s.ordinal } | get -o 0.bound) })
    { calls: ($bounded | where {|s| $s.bound in $CALLS }), outer: ($bounded | where {|s| $s.bound not-in $CALLS }) }
}

# The window's presents read against the renders that select them
def frames-of [rows: list<any>, flips: list<any>, pairs: list<any>, events: list<any>]: nothing -> record<frames: list<any>, load: list<any>, renders: int> {
    let chosen = (selection $events $pairs)
    let presented = ($flips | where status == 0 | group-by {|f| $f.ordinal | into string })
    let framed = ($rows | group-by {|r| $r.frame | into string })
    let read = ($chosen.frames | each {|s|
        let flip = ($presented | get ($s.ordinal | into string) | first)
        let row = (if $flip.frame == null { null } else { $framed | get -o ($flip.frame | into string) | get -o 0 })
        {
            present: $flip.present, frame: $flip.frame, ordinal: $s.ordinal, bound: $flip.bound,
            leg: ($row | get -o leg), cadence: ($row | get -o cadence),
            critical_us: ($row | get -o critical_us), submission_age_us: ($row | get -o submission_age_us),
            acceptance_interval_us: ($row | get -o acceptance_interval_us),
            upload_us: $s.upload_us, upload_interval_us: $s.upload_interval_us,
            renders: $s.renders, repeats: $s.repeats,
            shown: $s.shown, superseded: $s.superseded, unshown: $s.unshown,
            age_us: $s.age_us, shown_interval_us: $s.shown_interval_us,
            render_intervals_us: $s.render_intervals_us,
        }
    })
    { frames: ($read | where present == "frame"), load: ($read | where present != "frame"), renders: $chosen.renders }
}

# A set of frames pooled: intervals, selections, the age, and the path
def pooled [frames: list<any>, longest_superseded: int]: nothing -> record {
    let n = ($frames | length)
    let shown = ($frames | where shown)
    {
        frames: $n,
        presented_interval: (gauge measure stats ($frames | each {|f| $f.acceptance_interval_us })),
        upload_interval: (gauge measure stats ($frames | each {|f| $f.upload_interval_us })),
        render_interval: (gauge measure stats ($frames | each {|f| $f.render_intervals_us } | flatten)),
        age: (gauge measure stats ($shown | each {|f| $f.age_us })),
        shown_interval: (gauge measure stats ($frames | each {|f| $f.shown_interval_us })),
        shown: ($shown | length),
        superseded: ($frames | where superseded | length),
        repeated: (gauge measure total ($frames | each {|f| $f.repeats })),
        unshown_at_end: ($frames | where unshown | length),
        share_shown: (if $n == 0 { null } else { ($shown | length) / $n }),
        longest_superseded: $longest_superseded,
        longest_repeat: (if $n == 0 { 0 } else { $frames | each {|f| $f.repeats } | math max }),
        critical: (gauge measure stats ($frames | each {|f| $f.critical_us })),
        submission_age: (gauge measure stats ($frames | each {|f| $f.submission_age_us })),
    }
}

# A run's frames pooled whole and per leg, each leg's longest superseded its own
def run-legs [frames: list<any>]: nothing -> record<whole: record, legs: list<any>> {
    let legs = ($frames | each {|f| $f.leg } | compact | uniq)
    {
        whole: (pooled $frames (longest ($frames | each {|f| $f.superseded }))),
        legs: ($legs | each {|leg| let mine = ($frames | where leg == $leg); { leg: $leg } | merge (pooled $mine (longest ($mine | each {|f| $f.superseded }))) }),
    }
}

# One probed run read whole: its capture, its bundle, its pairing, its frames
export def run-reading [dir: path, --eps: int = 10000]: nothing -> record {
    let dir = ($dir | path expand)
    let read_id = (gauge identity read $dir)
    let id = $read_id.identity
    let chosen = (gauge report legs-for $dir $id "")
    let m = (gauge measure (open --raw ($dir | path join "api.out") | into binary) $chosen.legs --cap ($id | get -o cap | default 60))
    let asked = ($id | get -o mode.cadence)
    let base = {
        dir: $dir, seed: ($id | get -o mode.seed), cadence: $asked, identity_from: $read_id.from,
        capture: { schema: $m.schema, complete: $m.complete, valid: $m.valid, frames: $m.frames, under: $m.under },
    }
    let problems = (capture-problems $m $asked)
    if not ($problems | is-empty) { return ($base | merge { stage: "capture", refusals: $problems }) }
    let checked = (try { sdl bundle-check ($dir | path join "bundle") --guest {|a| guest-nonce $a } } catch {|e| { refusal: $e.msg } })
    if ($checked | get -o refusal) != null { return ($base | merge { stage: "bundle", refusals: [$checked.refusal] }) }
    let bundle = { profile: $checked.profile, run: $checked.run, reader: $checked.reader, trace: $checked.trace }
    let flips = (gauge measure flips $m)
    if $flips.source == null { return ($base | merge { stage: "flips", refusals: [$flips.reason], bundle: $bundle }) }
    let pair = (sdl pair $checked.events ($flips.flips | select status ordinal lo hi))
    let accepted = ($m.rows | where {|r| $r.flip_status == 0 and ($r.receipt_stamp | default 0) > 0 } | each {|r| $r.receipt_stamp })
    let period = ($HZ // ($id | get -o cap | default 60))
    let k = (present k-violations $accepted $period $eps)
    let pairing = {
        verdict: $pair.verdict, refusals: $pair.refusals, bracket: $pair.bracket, shifts: $pair.shifts,
        window: $pair.window, fit: $pair.fit, stalls: (stalls-of $pair.stalls $flips.flips),
    }
    let after = ($base | merge { bundle: $bundle, flips: { source: $flips.source, origin: $flips.origin }, pairing: $pairing, k: { eps: $eps, period: $period, violations: ($k | length), first: ($k | first 8) } })
    if not $pair.ok { return ($after | merge { stage: "pairing", refusals: ($pair.refusals | each {|r| $"($r.refusal): ($r.count)" }) }) }
    let read = (frames-of $m.rows $flips.flips $pair.pairs $checked.events)
    $after | merge { stage: null, refusals: [], renders: $read.renders, load: $read.load, frames: $read.frames }
}

# Runs, each a label, a run, and a directory, read and pooled by cadence and leg
export def analyse-runs [runs: list<any>, --eps: int = 10000]: nothing -> record {
    let runs = ($runs | each {|r|
        if $r.dir == null { { label: $r.label, run: $r.run, dir: null, stage: "run", refusals: ["its run's directory is not beside its report"] } } else {
            { label: $r.label, run: $r.run } | merge (run-reading $r.dir --eps $eps)
        }
    })
    let read = ($runs | where stage == null | each {|r| $r | merge (run-legs $r.frames) })
    let cadences = ($read | each {|r| $r.cadence } | uniq | sort)
    {
        runs: ($runs | each {|r|
            let held = ($read | where {|x| $x.label == $r.label and $x.run == $r.run } | get -o 0)
            $r | reject -o frames load | merge (if $held == null { {} } else { { whole: $held.whole, legs: $held.legs } })
        }),
        cadences: ($cadences | each {|c|
            let mine = ($read | where cadence == $c)
            let frames = ($mine | each {|r| $r.frames } | flatten)
            let legs = ($frames | each {|f| $f.leg } | compact | uniq)
            {
                cadence: $c,
                runs: ($mine | each {|r| $"($r.label) run ($r.run)" }),
                verdicts: ($mine | each {|r| $r.pairing.verdict } | uniq --count | each {|v| { verdict: $v.value, runs: $v.count } }),
                whole: (pooled $frames ($mine | each {|r| $r.whole.longest_superseded } | math max)),
                legs: ($legs | each {|leg|
                    let longest = ($mine | each {|r| $r.legs | where leg == $leg | get -o 0.longest_superseded | default 0 } | math max)
                    { leg: $leg } | merge (pooled ($frames | where leg == $leg) $longest)
                }),
            }
        }),
        unread: ($runs | where stage != null | each {|r| { label: $r.label, run: $r.run, stage: $r.stage, refusals: $r.refusals } }),
    }
}

# Every run of the probed batches under `base` read, pooled per cadence and leg
export def analyse [base: string, labels: list<string>, --eps: int = 10000]: nothing -> record {
    let base = ($base | path expand)
    let runs = ($labels | each {|l|
        let file = ($base | path join $l "gauge.nuon")
        (open $file).runs | each {|r| { label: $l, run: $r.run, dir: (gauge identity dirs $file $r | where {|d| ($d | path type) == "dir" } | get -o 0) } }
    } | flatten)
    analyse-runs $runs --eps $eps
}

# A run's capture measured for an observer control, its standing named
def observed [dir: path]: nothing -> record<whole: record, problems: list<string>, probed: bool, window: string, sound: string> {
    let read_id = (gauge identity read $dir)
    let id = $read_id.identity
    let chosen = (gauge report legs-for $dir $id "")
    let m = (gauge measure (open --raw ($dir | path join "api.out") | into binary) $chosen.legs --cap ($id | get -o cap | default 60))
    { whole: $m.whole, problems: (capture-problems $m ($id | get -o mode.cadence)), probed: (($id | get -o shim | default "") != ""), window: ($id | get -o window | default ""), sound: ($id | get -o mode.sound | default "" | into string) }
}

# A label list given on a command line as NUON, refused by name if malformed
def labels-of [flag: string, text: string]: nothing -> list<string> {
    let parsed = (try { $text | from nuon } catch { null })
    let listed = (if ($parsed | describe | str starts-with "list") { $parsed | all {|x| ($x | describe) == "string" } } else { false })
    if not $listed { error make { msg: $"--($flag) takes a NUON list of labels, such as \"[a b]\": ($text)" } }
    $parsed
}

# The shim's effect over the observer sets, the probed batches against plain
export def observer-reading [base: string, probed: list<string>, plain: list<string>]: nothing -> record {
    let base = ($base | path expand)
    let arm = {|labels: list<string>, shimmed: bool|
        $labels | each {|l|
            let file = ($base | path join $l "gauge.nuon")
            (open $file).runs | each {|r|
                let dir = (gauge identity dirs $file $r | where {|d| ($d | path type) == "dir" } | get -o 0)
                let name = $"($l) run ($r.run)"
                if $dir == null { { name: $name, whole: null, problems: ["its run's directory is not beside its report"] } } else {
                    let o = (observed $dir)
                    let named = (if $o.probed == $shimmed { [] } else if $shimmed { ["its identity names no shim"] } else { ["its identity names the shim"] })
                    { name: $name, whole: $o.whole, problems: ($o.problems ++ $named) }
                }
            }
        } | flatten
    }
    let arms = { probed: (do $arm $probed true), plain: (do $arm $plain false) }
    let fit = {|runs: list<any>| $runs | where {|r| $r.problems | is-empty } | each {|r| { name: $r.name, whole: $r.whole } } }
    let effect = (observer shim-effect (do $fit $arms.probed) (do $fit $arms.plain))
    let unfit = (($arms.probed ++ $arms.plain) | where {|r| not ($r.problems | is-empty) } | each {|r| $"($r.name): ($r.problems | str join '; ')" })
    {
        probed: ($arms.probed | each {|r| { name: $r.name, problems: $r.problems } }),
        plain: ($arms.plain | each {|r| { name: $r.name, problems: $r.problems } }),
        measures: $effect.measures,
        admissible: ($effect.admissible and ($unfit | is-empty)),
        problems: ($unfit ++ $effect.problems),
    }
}

# The observer sets' reading saved, each measure's effect against its noise
export def observer-sets [base: string, out: string, --probed: string, --plain: string] {
    let reading = (observer-reading $base (labels-of probed $probed) (labels-of plain $plain))
    $reading | to nuon --indent 1 | save --raw -f $out
    for m in $reading.measures {
        let ms = {|v: any| if $v == null { "-" } else { $"($v / 1000.0 | math round -p 3) ms" } }
        print $"proberuns: ($m.measure): probed (do $ms $m.probed), plain (do $ms $m.plain), effect (do $ms $m.effect), noise (do $ms $m.noise), (if $m.within { 'within' } else { 'past' }) its noise"
    }
    for p in $reading.problems { print $"proberuns: ($p)" }
    print $"proberuns: (if $reading.admissible { 'admissible: the probed readings stand for the unprobed program' } else { 'instrumented-only: the probed readings stand for the probed runs alone' })"
    print $"proberuns: ($out)"
}

# The window's cost over unprobed windowed batches against headless ones
export def window-reading [base: string, windowed: list<string>, headless: list<string>]: nothing -> record {
    let base = ($base | path expand)
    let arm = {|labels: list<string>, shown: bool|
        $labels | each {|l|
            let file = ($base | path join $l "gauge.nuon")
            (open $file).runs | each {|r|
                let dir = (gauge identity dirs $file $r | where {|d| ($d | path type) == "dir" } | get -o 0)
                let name = $"($l) run ($r.run)"
                if $dir == null { { name: $name, whole: null, sound: null, problems: ["its run's directory is not beside its report"] } } else {
                    let o = (observed $dir)
                    let shim = (if $o.probed { ["its identity names the shim"] } else { [] })
                    let window = (if ($o.window not-in ["" "none"]) == $shown { [] } else if $shown { ["its identity names no window"] } else { [$"its identity names the window ($o.window)"] })
                    { name: $name, whole: $o.whole, sound: $o.sound, problems: ($o.problems ++ $shim ++ $window) }
                }
            }
        } | flatten
    }
    let arms = { windowed: (do $arm $windowed true), headless: (do $arm $headless false) }
    let sounds = (($arms.windowed ++ $arms.headless) | get sound | compact | uniq)
    let sound = (if ($sounds | length) > 1 { [$"the arms' sound differs: ($sounds | str join ', ')"] } else { [] })
    let fit = {|runs: list<any>| $runs | where {|r| $r.problems | is-empty } | each {|r| { name: $r.name, whole: $r.whole } } }
    let effect = (observer window-effect (do $fit $arms.windowed) (do $fit $arms.headless))
    let unfit = (($arms.windowed ++ $arms.headless) | where {|r| not ($r.problems | is-empty) } | each {|r| $"($r.name): ($r.problems | str join '; ')" })
    {
        windowed: ($arms.windowed | each {|r| { name: $r.name, problems: $r.problems } }),
        headless: ($arms.headless | each {|r| { name: $r.name, problems: $r.problems } }),
        measures: $effect.measures,
        within: ($effect.admissible and ($unfit | is-empty) and ($sound | is-empty)),
        problems: ($unfit ++ $sound ++ $effect.problems),
    }
}

# The window's cost reading saved, each measure's effect against its noise
export def window-sets [base: string, out: string, --windowed: string, --headless: string] {
    let reading = (window-reading $base (labels-of windowed $windowed) (labels-of headless $headless))
    $reading | to nuon --indent 1 | save --raw -f $out
    for m in $reading.measures {
        let ms = {|v: any| if $v == null { "-" } else { $"($v / 1000.0 | math round -p 3) ms" } }
        print $"proberuns: the window's cost, ($m.measure): windowed (do $ms $m.windowed), headless (do $ms $m.headless), effect (do $ms $m.effect), noise (do $ms $m.noise), (if $m.within { 'within' } else { 'past' }) its noise"
    }
    for p in $reading.problems { print $"proberuns: ($p)" }
    print $"proberuns: the window's cost (if $reading.within { 'within the noise on every measure' } else { 'past the noise or unread on some measure' })"
    print $"proberuns: ($out)"
}

# A pooled summary's line: frames shown, superseded, and the intervals' medians
def line-of [s: record]: nothing -> string {
    let ms = {|v: any| if $v == null { "-" } else { $"($v / 1000.0 | math round -p 2) ms" } }
    let share = (if $s.share_shown == null { "-" } else { $"($s.share_shown * 100 | math round -p 1)%" })
    $"($s.frames) frames, ($s.shown) shown \(($share)), ($s.superseded) superseded \(longest ($s.longest_superseded)), ($s.repeated) repeats \(longest ($s.longest_repeat)), ($s.unshown_at_end) unshown at the end; presented (do $ms $s.presented_interval.median), uploads (do $ms $s.upload_interval.median), renders (do $ms $s.render_interval.median), shown (do $ms $s.shown_interval.median), age (do $ms $s.age.median), critical (do $ms $s.critical.median)"
}

# ProbeRuns' reading of the probed batches under `base`, saved
export def main [base: string, out: string, ...labels: string, --eps: int = 10000] {
    let reading = (analyse $base $labels --eps $eps)
    $reading | to nuon --indent 1 | save --raw -f $out
    for r in $reading.runs {
        if $r.stage != null {
            print $"proberuns: ($r.label) run ($r.run) unread at its ($r.stage): ($r.refusals | str join '; ')"
        } else {
            let stalls = ($r.pairing.stalls.calls | each {|s| $"($s.ordinal) at ($s.call_ms | math round -p 2) ms" })
            let named = (if ($stalls | is-empty) { "" } else { ": " + ($stalls | str join ", ") })
            print $"proberuns: ($r.label) run ($r.run), cadence ($r.cadence), pairing ($r.pairing.verdict), ($r.pairing.window.presents) presents of ($r.pairing.window.uploads) uploads, stalls ($stalls | length)($named), K violations ($r.k.violations)"
            print $"proberuns:   (line-of $r.whole)"
        }
    }
    for c in $reading.cadences {
        print $"proberuns: cadence ($c.cadence), ($c.runs | length) runs: (line-of $c.whole)"
        for l in $c.legs { print $"proberuns:   ($l.leg): (line-of $l)" }
    }
    print $"proberuns: ($out)"
}
