# A pair run's dumps read against a views run's key sets, printed as NUON
export def main [pair: path, sets: path, a: int = 0, b: int = 4] {
    let s = (open $pair)
    let v = (open $sets)
    let keys = [($v.dumps | get $a | get key) ($v.dumps | get $b | get key)]
    let ds = $s.dumps
    let settled = {|r| $r.missed_blocks == 0 and $r.building == 0 and $r.admitted == 0 and $r.tiles_built == 0 }
    let phases = ($ds | enumerate | each {|e|
        let i = $e.index
        let d = $e.item
        let view = ($i mod 2)
        let own = ($keys | get $view)
        let other = ($keys | get (1 - $view))
        let held = ($d | get key)
        let base = { dump: $i, frame: $d.0.frame, tiles: ($d | length), own_present: ($own | where {|k| $k in $held } | length), own: ($own | length), other_present: ($other | where {|k| $k in $held and $k not-in $own } | length) }
        if $i == 0 { $base } else {
            let prev = ($ds | get ($i - 1))
            let from = $prev.0.frame
            let rows = ($s.rows | where {|r| $r.frame > $from and $r.frame <= $d.0.frame })
            let missing = ($own | where {|k| $k not-in ($prev | get key) } | length)
            let kept = ($prev | where {|t| $t.key in $own })
            let moved = ($kept | where {|t| let n = ($d | where key == $t.key); ($n | is-empty) or $n.0.slot != $t.slot or $n.0.generation != $t.generation } | length)
            let first = ($rows | where {|r| $r.missed_blocks > 0 } | get -o 0.frame)
            let done = (if $first == null { null } else { $rows | where {|r| $r.frame > $first and (do $settled $r) } | get -o 0.frame })
            let building = ($rows | where {|r| $r.tiles_built > 0 } | each {|r| $"($r.frame):($r.tiles_built)/($r.evicted)" } | str join " ")
            $base | merge { missing: $missing, built: ($rows | get tiles_built | math sum), evicted: ($rows | get evicted | math sum), kept_moved: $moved, first_miss: $first, settled: $done, frames: (if $done == null { null } else { $done - $first }), boundaries: $building }
        }
    })
    let all = ($ds | enumerate | each {|e| $e.item | insert dump $e.index } | flatten)
    let sigs = ($all | group-by key | items {|k, ts| $ts | get sig | uniq | length } | where {|n| $n > 1 } | length)
    let gens = ($all | group-by slot | items {|sl, ts| $ts | sort-by dump | window 2 | where {|w| $w.1.generation < $w.0.generation or ($w.1.key != $w.0.key and $w.1.generation <= $w.0.generation) or ($w.1.key == $w.0.key and $w.1.generation != $w.0.generation and false) } | length } | math sum)
    let rows = $s.rows
    let fixed = ($rows | where {|r| $r.memory != null and $r.tile_bytes != null } | each {|r| $r.memory - $r.tile_bytes } | uniq)
    print ({
        valid: $s.valid, complete: $s.complete, invalid: $s.invalid,
        phases: $phases,
        texel_mismatches: $sigs, generation_faults: $gens,
        resets: ($rows | get tile_resets | uniq), slots_max: ($rows | get slots_used | math max), effective: ($rows | get -o slots_effective | uniq),
        tile_bytes_max: ($rows | get tile_bytes | math max), tile_peak: ($rows | get tile_peak | uniq), memory_max: ($rows | get memory | math max), memory_peak: ($rows | get memory_peak | uniq), fixed: $fixed,
    } | to nuon --indent 1)
}
