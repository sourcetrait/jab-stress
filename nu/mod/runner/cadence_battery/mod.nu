use (path self ../gauge)

# The battery's base new and its baseline's files present, the base made
export def ready [a: record]: nothing -> record {
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a battery is written once" } }
    let missing = ($a.baseline | where {|f| not ($f | path exists) })
    if ($missing | is-not-empty) { error make { msg: $"baseline missing: ($missing | str join ', ')" } }
    mkdir $a.base
    {}
}

# Release batches at their cadences, three runs each, compared with the baseline
export def main [a: record]: nothing -> record {
    mut done = []
    for b in $a.batches {
        gauge batch $a.fps $a.base $b.label release 3 [--cadence ($b.cadence | into string)]
        $done = ($done | append $b.label)
    }
    let files = ($a.batches | each {|b| $a.base | path join $b.label "gauge.nuon" } | append $a.baseline)
    let compares = ($a.fields | each {|f| gauge compare $a.fps $files $f $a.base })
    { batches: $done, compares: $compares }
}
