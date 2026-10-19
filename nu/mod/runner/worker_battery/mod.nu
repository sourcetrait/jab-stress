use (path self ../gauge)

# The battery's base new and every named image present, the base made
export def ready [a: record]: nothing -> record {
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a battery is written once" } }
    let missing = ($a.batches | where {|b| $b.image != "" and not ($b.image | path exists) })
    if ($missing | is-not-empty) { error make { msg: $"image missing: ($missing | get image | str join ', ')" } }
    mkdir $a.base
    {}
}

# Release batches at each one's workers and grain on the route, then compared
export def main [a: record]: nothing -> record {
    mut done = []
    for b in $a.batches {
        let image = (if $b.image == "" { [] } else { [--image $b.image] })
        let route = (if $a.route == "" { [] } else { [--route $a.route] })
        let cpu = (if $a.cpu { [--cpu] } else { [] })
        gauge batch $a.fps $a.base $b.label release $a.runs ([--cadence ($a.cadence | into string) --workers ($b.workers | into string) --grain ($b.grain | into string)] ++ $cpu ++ $image ++ $route)
        $done = ($done | append $b.label)
    }
    let files = ($a.batches | each {|b| $a.base | path join $b.label "gauge.nuon" })
    let compares = ($a.fields | each {|f| gauge compare $a.fps $files $f $a.base })
    { batches: $done, compares: $compares }
}
