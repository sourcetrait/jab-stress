use (path self ../gauge)

# Workers 3 to 7 at grains 0, 16, 32, and 64 on eight harts, then reversed
def batches [a: record]: nothing -> list<record> {
    let first = ([3 4 5 6 7] | each {|w| [0 16 32 64] | each {|g| { label: $"w($w)g($g)_1", harts: 8, workers: $w, grain: $g, image: $a.image } } } | flatten)
    $first ++ ($first | reverse | each {|b| $b | update label ($b.label | str replace '_1' '_2') })
}

# The sweep's base new and its image present, the base made; its batch count
export def ready [a: record]: nothing -> record {
    let all = (batches $a)
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a battery is written once" } }
    let missing = ($all | where {|b| $b.image != "" and not ($b.image | path exists) })
    if ($missing | is-not-empty) { error make { msg: $"image missing: ($missing | get image | str join ', ')" } }
    mkdir $a.base
    { batches: ($all | length) }
}

# Every batch measured on the route, then compared by field, diagnostic
export def main [a: record]: nothing -> record {
    let all = (batches $a)
    mut done = []
    for b in $all {
        let image = (if $b.image == "" { [] } else { [--image $b.image] })
        let route = (if $a.route == "" { [] } else { [--route $a.route] })
        let selection = (if $b.workers < 0 { [] } else { [--workers ($b.workers | into string) --grain ($b.grain | into string)] })
        gauge batch $a.fps $a.base $b.label release 3 ([--cadence "1" --harts ($b.harts | into string)] ++ $selection ++ $image ++ $route)
        $done = ($done | append $b.label)
    }
    let files = ($all | each {|b| $a.base | path join $b.label "gauge.nuon" })
    let compares = ([critical_us raster_us] | each {|f| gauge compare $a.fps $files $f $a.base --diagnostic })
    { batches: $done, compares: $compares }
}
