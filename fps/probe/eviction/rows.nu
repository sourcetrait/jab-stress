# The pool's counters a frame from a run's API capture, every frame from
# the first with a configuration of its own, for planning TileEviction.
use ../../../../jab/kit/fierce/nu/mod/gauge

def main [api: path] {
    let bytes = (open --raw $api | into binary)
    let cold = ((gauge stream $bytes).configs | last | get from)
    let m = (gauge measure $bytes [{ name: "start", places: [], pad: [] }])
    print ({ complete: $m.complete, valid: $m.valid, rows: ($m.rows | length), cold: $cold } | to nuon)
    let rows = ($m.rows | where {|r| $r.frame >= $cold })
    print ($rows | first 14 | select -o frame tiles_built build_us tiles_us overrun_us slots_used building missed_blocks admitted merged unprocessed evicted | to nuon --indent 1)
}
