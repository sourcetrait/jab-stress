# jab's tiles bin, run in a nu of its own
const TILES = (path self ../../../../../../jab/kit/fierce/nu/bin/nuance/tiles.nu | path expand)

# A capture's dumps keyed by tile header and texels' SHA-256, by jab's bin
export def keys [api: path, out: path] {
    ^$nu.current-exe $TILES keys $api $out
}

# The lit loop's most step between side-by-side pixels, by jab's bin
export def lit-steps [capture: path, rect: string, crosshair: int, out: path] {
    ^$nu.current-exe $TILES lit-steps $capture $rect $crosshair $out
}

# The handoff pair at `index` compared, by jab's bin
export def handoff [spec: path, index: int, out: path] {
    ^$nu.current-exe $TILES handoff $spec $index $out
}
