use (path self ../workergauge) [analyse]

# The frame's ceiling in microseconds
const CEILING_US = 15000

# The metrics a pair compares: median, 95th, frames over, and raster
const METRICS = [median p95 over raster]

# The frames a leg's run is read on, gaincurves' rule
def read-frames [mode: string, rows: list<any>]: nothing -> list<any> {
    if $mode == "play" { return $rows }
    let building = ($rows | enumerate | where {|e| ($e.item.tiles_built | default 0) > 0 } | get index)
    if ($building | is-empty) { [] } else { $rows | skip (($building | last) + 1) }
}

# A value by nearest rank at `q`, the median at 0.5
def rank [values: list<any>, q: float]: nothing -> any {
    let v = ($values | compact | sort)
    if ($v | is-empty) { return null }
    $v | get (((($v | length) * $q) | math ceil) - 1)
}

# A set of frames read: critical median and 95th, over, raster median
def stats [frames: list<any>]: nothing -> record {
    let c = ($frames | get critical_us)
    { median: (rank $c 0.5), p95: (rank $c 0.95), over: ($c | where {|x| $x >= $CEILING_US } | length), raster: (rank ($frames | get raster_us) 0.5), frames: ($frames | length) }
}

# Each run of a batch: its seed and its frames read, by leg and whole
def runs-of [mode: string, base: string, label: string]: nothing -> list<any> {
    let g = (open ($base | path join $label "gauge.nuon"))
    $g.runs | each {|r|
        let rows = ($g.rows | where run == $r.run)
        let legs = ($rows | get leg | uniq | where {|leg| $mode == "play" or $leg != "start" })
        let read = ($legs | each {|leg| { leg: $leg, frames: (read-frames $mode ($rows | where leg == $leg)) } })
        { label: $label, run: $r.run, seed: $r.seed, legs: ($read | each {|l| { leg: $l.leg } | merge (stats $l.frames) }), whole: (stats ($read | get frames | flatten)) }
    }
}

# Two readings' differences, the first less the second
def less [a: record, b: record]: nothing -> record {
    $METRICS | reduce --fold {} {|m, acc| $acc | insert $m (($a | get $m) - ($b | get $m)) }
}

# Differences summarised: lower, equal, higher, mean, least, greatest
def spread [d: list<any>]: nothing -> record {
    { lower: ($d | where {|x| $x < 0 } | length), equal: ($d | where {|x| $x == 0 } | length), higher: ($d | where {|x| $x > 0 } | length), mean: ($d | math avg), least: ($d | math min), most: ($d | math max), values: $d }
}

# A battery's matched pairs, refused when workergauge finds any problem
export def pairs [mode: string, base: string, a: string, b: string, count: int]: nothing -> record {
    let labels = (1..$count | each {|k| [$"($a)_($k)" $"($b)_($k)"] } | flatten)
    let doc = (analyse $mode $base $labels)
    if not ($doc.problems | is-empty) {
        error make { msg: $"grainpairs: the battery has problems, so no pairs are read: ($doc.problems | str join '; ')" }
    }
    let runs = ($labels | each {|l| runs-of $mode $base $l } | flatten)
    let pairs = (1..$count | each {|k|
        let second = ($runs | where label == $"($b)_($k)")
        $runs | where label == $"($a)_($k)" | each {|r|
            let p = ($second | where seed == $r.seed)
            if ($p | length) != 1 { error make { msg: $"grainpairs: ($r.label) run ($r.run), seed ($r.seed), has ($p | length) partners in ($b)_($k)" } }
            let q = ($p | first)
            let legs = ($r.legs | each {|l|
                let m = ($q.legs | where leg == $l.leg | get -o 0)
                if $m == null { error make { msg: $"grainpairs: ($q.label) run ($q.run) lacks the leg ($l.leg)" } }
                { leg: $l.leg } | merge (less $l $m)
            })
            { pair: $k, seed: $r.seed, first: $r.label, second: $q.label, whole: (less $r.whole $q.whole), legs: $legs }
        }
    } | flatten)
    let whole = ($METRICS | reduce --fold {} {|m, acc| $acc | insert $m (spread ($pairs | get whole | get $m)) })
    let leg_names = ($pairs | get 0.legs | get leg)
    let by_leg = ($leg_names | each {|leg|
        let ds = ($pairs | each {|p| $p.legs | where leg == $leg | first })
        { leg: $leg } | merge ($METRICS | reduce --fold {} {|m, acc| $acc | insert $m (spread ($ds | get $m)) })
    })
    let height = {|h: string|
        let mine = ($runs | where {|r| $r.label starts-with $"($h)_" })
        $METRICS | reduce --fold { height: $h, runs: ($mine | length) } {|m, acc|
            let v = ($mine | get whole | get $m)
            $acc | insert $m { least: ($v | math min), most: ($v | math max), range: (($v | math max) - ($v | math min)) }
        }
    }
    let batches = ($labels | each {|l|
        let mine = ($runs | where label == $l)
        { label: $l, seeds: ($mine | get seed), median: ($mine | get whole.median), p95: ($mine | get whole.p95), over: ($mine | get whole.over), raster: ($mine | get whole.raster), median_mean: ($mine | get whole.median | math avg), raster_mean: ($mine | get whole.raster | math avg) }
    })
    { mode: $mode, base: $base, first: $a, second: $b, problems: $doc.problems, pairs: $pairs, whole: $whole, legs: $by_leg, heights: [(do $height $a) (do $height $b)], batches: $batches }
}

# A reading as lines in milliseconds: pairs, spreads, heights, batches
def report [r: record]: nothing -> string {
    let ms = {|us| if $us == null { "-" } else { ($us / 1000) | math round --precision 2 | into string } }
    let line = {|name: string, s: record, unit: string|
        if $unit == "frames" {
            $"($name): ($r.first) lower in ($s.lower), equal in ($s.equal), higher in ($s.higher) of ($s.values | length); mean ($s.mean | math round --precision 2), least ($s.least), greatest ($s.most) frames"
        } else {
            $"($name): ($r.first) lower in ($s.lower), equal in ($s.equal), higher in ($s.higher) of ($s.values | length); mean (do $ms $s.mean), least (do $ms $s.least), greatest (do $ms $s.most) ms"
        }
    }
    let pairs = ($r.pairs | each {|p| $"  pair ($p.pair) seed ($p.seed): median (do $ms $p.whole.median), p95 (do $ms $p.whole.p95), over ($p.whole.over), raster (do $ms $p.whole.raster)" })
    let whole = ($METRICS | each {|m| do $line $"whole ($m)" ($r.whole | get $m) (if $m == "over" { "frames" } else { "ms" }) })
    let legs = ($r.legs | each {|l| [median p95] | each {|m| do $line $"($l.leg) ($m)" ($l | get $m) "ms" } } | flatten)
    let heights = ($r.heights | each {|h| $"($h.height), ($h.runs) runs: median (do $ms $h.median.least) to (do $ms $h.median.most), range (do $ms $h.median.range); p95 (do $ms $h.p95.least) to (do $ms $h.p95.most); over ($h.over.least) to ($h.over.most); raster (do $ms $h.raster.least) to (do $ms $h.raster.most)" })
    let batches = ($r.batches | each {|b| $"  ($b.label): medians ($b.median | each {|v| do $ms $v } | str join ' '), mean (do $ms $b.median_mean); raster mean (do $ms $b.raster_mean)" })
    [$"grainpairs ($r.mode) ($r.base): ($r.first) less ($r.second), by pair and seed"] ++ $pairs ++ $whole ++ $legs ++ $heights ++ ["batches:"] ++ $batches | str join "\n"
}

# A battery's two band heights read as matched pairs, saved and printed
export def main [mode: string, base: string, out: string, a: string, b: string, count: int]: nothing -> nothing {
    let r = (pairs $mode $base $a $b $count)
    $r | to nuon --indent 1 | save --raw -f $out
    print (report $r)
}
