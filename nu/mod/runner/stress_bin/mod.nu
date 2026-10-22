# The log's directory made, the bin found in the workbench
export def ready [a: record]: nothing -> record {
    let bin = ($a.stress | path join nu bin $"($a.bin).nu")
    if not ($bin | path exists) { error make { msg: $"no workbench bin ($bin)" } }
    mkdir ($a.log | path dirname)
    {}
}

# A workbench bin's verb run in the jab-stress checkout, its output logged
export def main [a: record]: nothing -> record {
    let given = ($a.env | reduce --fold {} {|e, acc| $acc | insert $e.name $e.value })
    cd $a.stress
    let r = (with-env $given { ^$nu.current-exe ($a.stress | path join nu bin $"($a.bin).nu") $a.verb ...$a.words | complete })
    ($r.stdout + $r.stderr) | save --raw -f $a.log
    if $r.exit_code != 0 { error make { msg: $"($a.bin) ($a.verb) exited ($r.exit_code): ($r.stdout + $r.stderr | lines | last 4 | str join ' | ' | str substring 0..900)" } }
    { exit: $r.exit_code, last: ($r.stdout | lines | last 3 | str join ' | ' | str substring 0..400) }
}
