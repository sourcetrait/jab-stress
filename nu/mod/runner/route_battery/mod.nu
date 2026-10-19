use (path self ../gauge)

# The battery's base new and its image present, the base made
export def ready [a: record]: nothing -> record {
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a battery is written once" } }
    if not ($a.image | path exists) { error make { msg: $"image missing: ($a.image)" } }
    mkdir $a.base
    {}
}

# Debug batches on the image, each on its route and workers
export def main [a: record]: nothing -> record {
    mut done = []
    for b in $a.batches {
        let route = (if $b.route == "" { [] } else { [--route $b.route] })
        let workers = (if $b.workers < 0 { [] } else { [--workers ($b.workers | into string)] })
        gauge batch $a.fps $a.base $b.label debug $a.runs ([--image $a.image] ++ $route ++ $workers)
        $done = ($done | append $b.label)
    }
    { batches: $done }
}
