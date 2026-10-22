# A compiled tree's tile.nuon rewritten to name each source under `content`
export def rooted [tree: path, content: path]: nothing -> nothing {
    let tiles = ($tree | path join "tile.nuon")
    open $tiles | each {|t| $t | update source (if $t.source == "" { "" } else { $content | path join $t.source }) } | to nuon | save -f $tiles
}
