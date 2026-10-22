# The battery checked before its launch, its base made and its batches kept
export def ready [a: record]: nothing -> record {
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a battery is written once" } }
    let twice = ($a.batches | get label | uniq --repeated)
    if ($twice | is-not-empty) { error make { msg: $"a label twice: ($twice | str join ', ')" } }
    mkdir $a.base
    $a.batches | to nuon --indent 2 | save --raw ($a.base | path join "batches.nuon")
    {}
}

# Each batch's gauge run in order under its own environment, each logged
export def main [a: record]: nothing -> record {
    mut done = []
    for b in $a.batches {
        let given = ($b.env | reduce --fold {} {|e, acc| $acc | insert $e.name $e.value })
        cd $a.fps
        let r = (with-env $given { ^$nu.current-exe ($a.fps | path join nu bin nuance.nu) gauge run ...$b.words --out ($a.base | path join $b.label) --label $b.label | complete })
        ($r.stdout + $r.stderr) | save --raw -f ($a.base | path join $"($b.label).log")
        if $r.exit_code != 0 { error make { msg: $"($b.label) exited ($r.exit_code): ($r.stdout + $r.stderr | lines | last 6 | str join ' | ' | str substring 0..900)" } }
        $done = ($done | append $b.label)
    }
    { batches: $done }
}
