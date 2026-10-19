use (path self ../gauge)

# The battery's base new and every named image present, the base made
export def ready [a: record]: nothing -> record {
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a battery is written once" } }
    let missing = ($a.batches | where {|b| $b.image != "" and not ($b.image | path exists) })
    if ($missing | is-not-empty) { error make { msg: $"image missing: ($missing | get image | str join ', ')" } }
    mkdir $a.base
    {}
}

# Release batches at cadence 0, each on its image or the fresh build, compared
export def main [a: record]: nothing -> record {
    mut done = []
    for b in $a.batches {
        let extra = (if $b.image == "" { [] } else { [--image $b.image] })
        gauge batch $a.fps $a.base $b.label release 3 ([--cadence "0"] ++ $extra)
        $done = ($done | append $b.label)
    }
    let files = ($a.batches | each {|b| $a.base | path join $b.label "gauge.nuon" })
    let compares = ($a.fields | each {|f| gauge compare $a.fps $files $f $a.base })
    { batches: $done, compares: $compares }
}
