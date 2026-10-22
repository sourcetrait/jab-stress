use (path self ../../../../../jab/kit/fierce/nu/mod/gauge)

# The frame period at 60 frames a second, in microseconds
const PERIOD = (1000000 / 60)

# The ceiling in microseconds, judged on the critical path's median
const CEILING = 15000

# Least, median, 95th, 99th, and greatest by nearest rank, null-free
def spread [values: list<any>]: nothing -> record {
    let v = ($values | compact | sort)
    let n = ($v | length)
    if $n == 0 { return { n: 0, least: null, median: null, p95: null, p99: null, most: null } }
    let rank = {|q: float| $v | get ((($q * $n) | math ceil) - 1) }
    { n: $n, least: ($v | first), median: (do $rank 0.5), p95: (do $rank 0.95), p99: (do $rank 0.99), most: ($v | last) }
}

# Each row with its call interval from the presented flip before it
def started [rows: list<any>]: nothing -> list<any> {
    mut previous: any = null
    mut late = false
    mut out = []
    for r in $rows {
        let start = (if $r.flip_status == 0 { $r.flip_done_us - $r.flip_us } else { null })
        let interval = (if $start == null or $previous == null { null } else { $start - $previous })
        $out = ($out | append ($r | insert call_interval_us $interval | insert after_late $late))
        if $start != null { $previous = $start }
        $late = ($r.critical_us >= $PERIOD)
    }
    $out
}

# The cadence lane: every run pooled per cadence and leg
export def analyse [base: string, labels: list<string>]: nothing -> record {
    let batches = ($labels | each {|l|
        let file = ($base | path join $l "gauge.nuon")
        let g = (open $file)
        let runs = ($g.runs | each {|r|
            let request = (gauge identity request $file $r ($g | get -o identity))
            let rows = (started ($g.rows | where run == $r.run))
            {
                label: $l, cadence: $request.cadence, run: $r.run, rows: $rows,
                standing: { complete: $r.measured.complete, valid: $r.measured.valid, seeded: $r.measured.seeded, cadences: $r.measured.cadences },
                cpu_over_wall: (if $r.ran.wall_seconds == null or $r.ran.wall_seconds == 0 { null } else { $r.ran.cpu_seconds / $r.ran.wall_seconds }),
                outcomes: $r.measured.outcomes,
            }
        })
        $runs
    } | flatten)
    let cadences = ($batches | get cadence | uniq | sort)
    let per = ($cadences | each {|c|
        let runs = ($batches | where cadence == $c)
        let rows = ($runs | get rows | flatten)
        let legs = ($rows | get leg | uniq)
        {
            cadence: $c,
            runs: ($runs | length),
            standings: ($runs | each {|r| $r.standing }),
            cpu_over_wall: ($runs | get cpu_over_wall),
            outcomes: ($runs | each {|r| { label: $r.label, run: $r.run, rounds: $r.outcomes.rounds, androids: $r.outcomes.androids, struck: $r.outcomes.struck, pickups: $r.outcomes.pickups } }),
            whole: (summary $rows),
            legs: ($legs | each {|leg| { leg: $leg } | merge (summary ($rows | where leg == $leg)) }),
        }
    })
    { cadences: $per }
}

# A set of rows summarised: intervals, paths, waits, flips, and the tail
def summary [rows: list<any>]: nothing -> record {
    let presented = ($rows | where flip_status == 0)
    {
        frames: ($rows | length),
        completion_interval: (spread ($rows | each {|r| $r | get -o completion_interval_us | default ($r | get -o flip_interval_us) })),
        call_interval: (spread ($rows | get call_interval_us)),
        submission_age: (spread ($rows | get submission_age_us)),
        critical: (spread ($rows | get critical_us)),
        draw: (spread ($rows | get draw_us)),
        wait: (spread ($rows | get wait_us)),
        pacing: (spread ($rows | get pacing_us)),
        await: (spread ($rows | get await_us)),
        wakes: ($rows | get wakes | math sum),
        attempts: ($rows | get flip_attempts | math sum),
        refusals: ($rows | get refusals | math sum),
        flips_early: ($rows | where flip_status == 1 | length),
        flips_failed: ($rows | where {|r| $r.flip_status > 1 } | length),
        tail: ($rows | where {|r| $r.critical_us >= $CEILING } | length),
        fast: ($rows | where {|r| $r.critical_us < $PERIOD } | length),
        fast_waited: ($rows | where {|r| $r.critical_us < $PERIOD and $r.wait_us > 0 } | length),
        catch_up: ($rows | where {|r| $r.after_late and $r.call_interval_us != null and $r.call_interval_us < ($PERIOD / 2) } | length),
        presented: ($presented | length),
    }
}

# The cadence lane's summary of the batches under `base`, saved
export def main [base: string, out: string, ...labels: string]: nothing -> nothing {
    analyse $base $labels | to nuon --indent 1 | save --raw -f $out
    print $"lane: ($labels | length) batches summarised to ($out)"
}
