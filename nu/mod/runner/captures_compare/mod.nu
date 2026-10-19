use (path self ../captures)

# Each set's directory new under the root
export def ready [a: record]: nothing -> record {
    captures fresh $a.root $a.sets
    {}
}

# Every set's maps' poses captured, saved, and held to the base's by kind
export def main [a: record]: nothing -> record {
    let rows = (captures by-set $a.nuance $a.kernel $a.root $a.sets $a.maps)
    $rows | to nuon | save -f ($a.root | path join "new1_captures.nuon")
    let base = (open $a.base)
    let compared = ($rows | each {|r|
        let kind = ($r.set | str replace 'new1_' '')
        let want = ($base | where set == $"base_($kind)" and map == $r.map and pose == $r.pose | get -o 0.capture)
        { kind: $kind, map: $r.map, pose: $r.pose, same: ($want == $r.capture) }
    })
    { captures: ($rows | length), exits: ($rows | get exit | uniq), same: ($compared | where same | length), differ: ($compared | where {|c| not $c.same } | each {|c| $"($c.kind) ($c.pose)" }) }
}
