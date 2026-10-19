# The log's directory made
export def ready [a: record]: nothing -> record {
    mkdir ($a.log | path dirname)
    {}
}

# fierce's tests through jab's driver, the log saved, its gauge lines returned
export def main [a: record]: nothing -> record {
    let jab = ($a.fps | path join .. .. | path expand)
    cd $jab
    let set = (if $a.set == "" { [] } else { [--set $a.set] })
    let test = (^$nu.current-exe ($jab | path join nu bin do.nu) test $a.program ...$set | complete)
    ($test.stdout + $test.stderr) | save --raw -f $a.log
    let lines = ($test.stdout | lines)
    let ok = (($test.exit_code == 0) and ($lines | any {|l| $l == "fps: ok" }))
    let gauge = ($lines | where {|l| $l starts-with "fps: the gauge" } | str join " | ")
    if not $ok {
        error make { msg: $"do test failed: exit ($test.exit_code); ($lines | last 2 | str join ' | ' | str substring 0..800) ($test.stderr | str substring 0..1500)" }
    }
    { ok: $ok, exit: $test.exit_code, gauge: ($gauge | str substring 0..400) }
}
