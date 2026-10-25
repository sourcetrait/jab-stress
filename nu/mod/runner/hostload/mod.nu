# Linux's process filesystem, which every reading reads
const PROC = "/proc"

# The interval between a step's readings
export const INTERVAL = 10sec

# The cores a foreign or unknown process reaches in an interval to be named
export const NAMED_CORES = 0.1

# How long a step's end waits for the sampler's final reading
const FINAL_WAIT = 60sec

# The clock ticks a second of the process table's CPU times
export def clock-ticks []: nothing -> int {
    ^getconf CLK_TCK | str trim | into int
}

# The step's process tree's root, this process, by its pid and start
export def root []: nothing -> record<pid: int, start: oneof<int, nothing>> {
    let me = (process-of ($PROC | path join ($nu.pid | into string)))
    { pid: $nu.pid, start: ($me | get -o start) }
}

# One reading: its time since boot, the host's busy CPU, and every process
export def reading [seq: int, ticks: int]: nothing -> record {
    let at = (try { open --raw ($PROC | path join "uptime") | decode | split row " " | first | into float } catch { null })
    let busy = (try { busy-ticks } catch { null })
    let listed = (try { ls $PROC | where type == dir | get name | where {|d| ($d | path basename) =~ '^[0-9]+$' } } catch { null })
    let failed = (if $at == null or $listed == null { $"($PROC) could not be read" } else { null })
    let processes = (if $failed == null { $listed | each {|d| process-of $d } | compact } else { [] })
    { kind: "reading", seq: $seq, at: $at, ticks: $ticks, busy: $busy, failed: $failed, processes: $processes }
}

# A reading appended to a step's file, one NUON line
export def append-reading [file: path, seq: int, ticks: int]: nothing -> nothing {
    $"(reading $seq $ticks | to nuon)(char nl)" | save --append --raw $file
}

# Readings every INTERVAL into `file` from `first`, the last once told to stop
export def sample [file: path, first: int, ticks: int]: nothing -> nothing {
    mut seq = $first
    loop {
        let told = (try { job recv --timeout $INTERVAL } catch { null })
        append-reading $file $seq $ticks
        $seq += 1
        if $told != null { break }
    }
    "done" | job send 0
}

# The sampler told to stop, whether its final reading was written in time
export def stop [job: int]: nothing -> bool {
    "stop" | job send $job
    (try { job recv --timeout $FINAL_WAIT } catch { null }) == "done"
}

# What a step's readings show: coverage, gaps, foreign work, unattributed CPU
export def summary [file: path, root: record, final: bool]: nothing -> record {
    let lines = (open --raw $file | decode | lines | where {|l| $l != "" } | each {|l| $l | from nuon })
    let good = ($lines | where {|x| $x.failed == null })
    let gaps = ($lines | where {|x| $x.failed != null } | each {|x| { seq: $x.seq, at: $x.at, why: $x.failed } })
    let classes = (classes-of $good $root)
    mut named = []
    mut unbounded = []
    mut unattributed = []
    for pair in ($good | window 2) {
        let a = $pair.0
        let b = $pair.1
        let ticks = $b.ticks
        let before = ($a.processes | reduce --fold {} {|p, acc| $acc | upsert $"($p.pid):($p.start)" $p.cpu })
        let class_of = ($classes | get ($b.seq | into string))
        mut attributed = 0
        for p in $b.processes {
            let key = $"($p.pid):($p.start)"
            let was = ($before | get -o $key)
            let born = ($p.start / $ticks)
            let bound = (if $was != null { { from: $a.at, cpu: $was } } else if $born >= $a.at { { from: $born, cpu: 0 } } else { null })
            if $bound == null {
                $unbounded = ($unbounded | append { pid: $p.pid, start: $p.start, name: $p.name, from: $a.at, to: $b.at })
                continue
            }
            let delta = ($p.cpu - $bound.cpu)
            $attributed += $delta
            let span = ($b.at - $bound.from)
            let cores = (if $span > 0 { $delta / $ticks / $span } else { null })
            let class = ($class_of | get -o $key | default "unknown")
            if $class != "step" and $cores != null and $cores >= $NAMED_CORES {
                $named = ($named | append { class: $class, pid: $p.pid, start: $p.start, name: $p.name, from: $bound.from, to: $b.at, cores: ($cores | math round --precision 3) })
            }
        }
        let seconds = ($b.at - $a.at)
        let idle = (if $a.busy == null or $b.busy == null or $seconds <= 0 { null } else { ($b.busy - $a.busy - $attributed) / $ticks / $seconds | math round --precision 3 })
        $unattributed = ($unattributed | append { from: $a.at, to: $b.at, cores: $idle })
    }
    {
        file: ($file | path basename),
        root: $root,
        readings: ($lines | length),
        covered: { from: ($good | get -o 0.at), to: ($good | last | get -o at) },
        final: $final,
        gaps: $gaps,
        unbounded: $unbounded,
        named: $named,
        unattributed: $unattributed,
    }
}

# Each reading's processes classed the step's, foreign, or unknown, by its seq
def classes-of [good: list<any>, root: record]: nothing -> record {
    mut established = {}
    mut first_parent = {}
    mut out = {}
    for r in $good {
        let by_pid = ($r.processes | reduce --fold {} {|p, acc| $acc | upsert ($p.pid | into string) $p })
        mut here = {}
        for p in $r.processes {
            let key = $"($p.pid):($p.start)"
            let class = (class-of $p $by_pid $root $established $first_parent)
            if $class != "unknown" and ($established | get -o $key) == null { $established = ($established | upsert $key $class) }
            if ($first_parent | get -o $key) == null { $first_parent = ($first_parent | upsert $key $p.parent) }
            $here = ($here | upsert $key $class)
        }
        $out = ($out | upsert ($r.seq | into string) $here)
    }
    $out
}

# A process's class by its parents while they lived, a broken chain unknown
def class-of [p: record, by_pid: record, root: record, established: record, first_parent: record]: nothing -> string {
    mut cur = $p
    for hop in 0..512 {
        let key = $"($cur.pid):($cur.start)"
        if $cur.pid == $root.pid and $cur.start == $root.start { return "step" }
        let known = ($established | get -o $key)
        if $known != null { return $known }
        let first = ($first_parent | get -o $key)
        if $first != null and $first != $cur.parent { return "unknown" }
        if $cur.parent == 0 { return "foreign" }
        let parent = ($by_pid | get -o ($cur.parent | into string))
        if $parent == null or $parent.start > $cur.start { return "unknown" }
        $cur = $parent
    }
    "unknown"
}

# The host's busy CPU ticks over every CPU, from the process filesystem's stat
def busy-ticks []: nothing -> int {
    let cpu = (open --raw ($PROC | path join "stat") | decode | lines | first | split row --regex '\s+')
    [1 2 3 6 7 8] | each {|i| $cpu | get $i | into int } | math sum
}

# A process's pid, start, parent, name, and CPU ticks from its stat, null if gone
def process-of [dir: string]: nothing -> any {
    let text = (try { open --raw ($dir | path join "stat") | decode } catch { null })
    if $text == null { return null }
    let open_at = ($text | str index-of "(")
    let close_at = ($text | str index-of --end ")")
    if $open_at < 0 or $close_at <= $open_at { return null }
    let after = ($close_at + 2)
    let named = ($open_at + 1)
    let fields = ($text | str substring $after.. | split row " ")
    if ($fields | length) < 20 { return null }
    {
        pid: ($dir | path basename | into int),
        start: ($fields | get 19 | into int),
        parent: ($fields | get 1 | into int),
        name: ($text | str substring $named..<$close_at),
        cpu: (($fields | get 11 | into int) + ($fields | get 12 | into int)),
    }
}
