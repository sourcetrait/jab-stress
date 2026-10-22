use (path self ../../../../../../../jab/kit/fierce/nu/mod/suite/tiles) [handoff-holds builder-holds]
use (path self ../../../../fierce/places)

# The game's directory in jab, checked out beside the workbench
const GAME = (path self ../../../../../../../jab/kit/fierce | path expand)

# The map both fixtures read, the game's render_1
def render-one []: nothing -> record {
    open ($GAME | path join content map render_1.nuon)
}

# handoff-holds alone on the debug tree, its reading saved and its time printed
export def holds [out: path]: nothing -> nothing {
    let p = (places)
    let s = (date now)
    let r = (handoff-holds $p.kernel $p.image $out "DEBUG,COUNT" (render-one) $GAME)
    $r | to nuon --indent 1 | save -f ($out | path join handoff_read.nuon)
    print $'took ((date now) - $s)'
}

# builder-holds alone on the debug tree, its reading saved and printed
export def builder [out: path]: nothing -> nothing {
    let p = (places)
    let r = (builder-holds $p.kernel $p.image $out "DEBUG" (render-one) $GAME)
    $r | to nuon --indent 1 | save -f ($out | path join builder.nuon)
    print ($r | reject by_level | to nuon)
}

# builder-holds alone on another image beside the debug kernel, printed
export def builder-on [image: path, out: path]: nothing -> nothing {
    let p = (places)
    let r = (builder-holds $p.kernel $image $out "DEBUG" (render-one) $GAME)
    print ($r | reject by_level | to nuon)
}
