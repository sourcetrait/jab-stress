# The rows gauge.nu's stream reads from a run's API capture, the pool's
# counters a frame, for a probe of a handoff run.
use ../../../../jab/kit/fierce/nu/mod/gauge

def main [api: path] {
    let s = (gauge stream (open --raw $api | into binary))
    print ($s | columns | to nuon)
    let m = (gauge measure (open --raw $api | into binary) [{ name: "start", places: [], pad: [] }])
    print ({ complete: $m.complete, valid: $m.valid, rows: ($m.rows | length), problems: ($m.problems | first 3) } | to nuon)
    print ($m.rows | last 8 | select -o frame leg missed_blocks building admitted dropped filtered tiles_built slots_used evicted tiled | to nuon)
}
