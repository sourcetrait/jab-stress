# Nothing to make before the launch
export def ready [a: record]: nothing -> record {
    {}
}

# Each program's tests through jab's driver in turn, one log, the failures' heads
export def main [a: record]: nothing -> record {
    cd $a.jab
    let runs = ($a.paths | each {|p|
        let r = (^$nu.current-exe ($a.jab | path join nu bin do.nu) test $p | complete)
        { path: $p, exit: $r.exit_code, text: ($r.stdout + "\n--- stderr\n" + $r.stderr) }
    })
    mkdir ($a.log | path dirname)
    $runs | each {|r| $"=== ($r.path) exit ($r.exit)\n($r.text)" } | str join "\n" | save --raw -f $a.log
    let heads = ($runs | where exit != 0 | each {|r|
        let ls = ($r.text | lines)
        let i = ($ls | enumerate | where {|e| $e.item starts-with "  x " } | get -o 0.index)
        { path: $r.path, head: (if $i == null { "" } else { $ls | get $i | str substring 0..300 }) }
    })
    { exits: ($runs | each {|r| { path: $r.path, exit: $r.exit } }), failed: $heads }
}
