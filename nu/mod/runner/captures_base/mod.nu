use (path self ../captures)

# Each set's directory new under the root, the root made
export def ready [a: record]: nothing -> record {
    captures fresh $a.root $a.sets
    mkdir $a.root
    {}
}

# Every set's maps' poses captured on the kernel, the base's captures saved
export def main [a: record]: nothing -> record {
    let rows = (captures by-set $a.nuance $a.kernel $a.root $a.sets $a.maps)
    $rows | to nuon | save -f ($a.root | path join "base_captures.nuon")
    { captures: ($rows | length), exits: ($rows | get exit | uniq) }
}
