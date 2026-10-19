use (path self ../captures)

# The captures' directory new under the root, then made
export def ready [a: record]: nothing -> record {
    let caps = ($a.root | path join captures)
    if ($caps | path exists) { error make { msg: $"the captures exist: ($caps)" } }
    mkdir $caps
    {}
}

# Every map's poses captured on each set, maps outermost, held to the base set's
export def main [a: record]: nothing -> record {
    let caps = ($a.root | path join captures)
    let rows = ($a.maps | each {|m| $a.sets | each {|s| captures shot $a.nuance $a.kernel $caps $s $m } | flatten } | flatten)
    $rows | to nuon | save -f ($a.root | path join "captures.nuon")
    let base = ($rows | where set == $a.base)
    let compared = ($rows | where set != $a.base | each {|r|
        let want = ($base | where map == $r.map and pose == $r.pose | get -o 0.capture)
        { set: $r.set, map: $r.map, pose: $r.pose, same: ($want != null and $want == $r.capture) }
    })
    { captures: ($rows | length), exits: ($rows | get exit | uniq), base: ($base | length), same: ($compared | where same | length), differ: ($compared | where {|c| not $c.same } | each {|c| $"($c.set) ($c.pose)" }) }
}
