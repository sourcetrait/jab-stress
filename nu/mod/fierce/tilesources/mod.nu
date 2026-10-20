# A compiled tree's tile.nuon naming each source under `content`, as a
# checkout compiled it before jab c804ccb, which named the content's absolute
# path where the compiler now names the source relative to the content
export def rooted [tree: path, content: path]: nothing -> nothing {
    let tiles = ($tree | path join "tile.nuon")
    open $tiles | each {|t| $t | update source (if $t.source == "" { "" } else { $content | path join $t.source }) } | to nuon | save -f $tiles
}
