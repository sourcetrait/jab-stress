use (path self ../../../../../../../../jab/kit/fierce/nu/mod/gauge)

# The pool's counters a frame from a capture, from its own configuration on
export def main [api: path]: nothing -> nothing {
    let bytes = (open --raw $api | into binary)
    let cold = ((gauge stream $bytes).configs | last | get from)
    let m = (gauge measure $bytes [{ name: "start", places: [], pad: [] }])
    print ({ complete: $m.complete, valid: $m.valid, rows: ($m.rows | length), cold: $cold } | to nuon)
    let rows = ($m.rows | where {|r| $r.frame >= $cold })
    print ($rows | first 14 | select -o frame tiles_built build_us tiles_us overrun_us slots_used building missed_blocks admitted merged unprocessed evicted | to nuon --indent 1)
}
