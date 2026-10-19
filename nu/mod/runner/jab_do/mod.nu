# The log's directory made
export def ready [a: record]: nothing -> record {
    mkdir ($a.log | path dirname)
    {}
}

# A root driver's verb in the jab checkout under the environment given, logged
export def main [a: record]: nothing -> record {
    let given = ($a.env | reduce --fold {} {|e, acc| $acc | insert $e.name $e.value })
    cd $a.jab
    let r = (with-env $given { ^$nu.current-exe ($a.jab | path join nu bin $"($a.bin).nu") $a.verb ...$a.words | complete })
    ($r.stdout + $r.stderr) | save --raw -f $a.log
    if $r.exit_code != 0 { error make { msg: $"($a.bin) ($a.verb) exited ($r.exit_code): ($r.stdout + $r.stderr | lines | last 4 | str join ' | ' | str substring 0..900)" } }
    { exit: $r.exit_code, last: ($r.stdout | lines | last 3 | str join ' | ' | str substring 0..400) }
}
