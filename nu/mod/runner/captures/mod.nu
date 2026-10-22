# A set's image's poses of a map captured by the pose bin, a row a screen
export def shot [nuance: path, kernel: path, root: path, set: record, map: record]: nothing -> list<record> {
    let out = ($root | path join $set.name $map.map)
    let r = (^$nu.current-exe $nuance $map.map $set.image $map.poses $out $kernel | complete)
    ($r.stdout + $r.stderr) | save --raw -f ($root | path join $"($set.name)_($map.map).log")
    glob ($out | path join "*" "screen.ppm") | each {|f|
        { set: $set.name, map: $map.map, pose: ($f | path dirname | path basename), capture: (open --raw $f | hash sha256), exit: $r.exit_code }
    }
}

# Every set's maps captured, sets outermost, a row a screen
export def by-set [nuance: path, kernel: path, root: path, sets: list<record>, maps: list<record>]: nothing -> list<record> {
    $sets | each {|s| $maps | each {|m| shot $nuance $kernel $root $s $m } | flatten } | flatten
}

# Each set's directory under `root` refused where it exists
export def fresh [root: path, sets: list<record>]: nothing -> nothing {
    for s in $sets { if ($root | path join $s.name | path exists) { error make { msg: $"($s.name) exists under ($root)" } } }
}
