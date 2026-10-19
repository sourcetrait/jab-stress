# The log's directory made
export def ready [a: record]: nothing -> record {
    mkdir ($a.log | path dirname)
    {}
}

# jab's whole suite through its driver, the log saved, its table's rows returned
export def main [a: record]: nothing -> record {
    cd $a.jab
    let r = (^$nu.current-exe ($a.jab | path join nu bin do.nu) test | complete)
    let text = ($r.stdout + "\n--- stderr\n" + $r.stderr)
    $text | save --raw -f $a.log
    let table = ($text | lines | where {|l| ($l =~ '│') and (($l =~ 'true') or ($l =~ 'false')) })
    let failed = ($table | where {|l| $l =~ 'false' })
    let n = ($text | str length)
    let start = ([0 ($n - 1500)] | math max)
    { exit: $r.exit_code, rows: ($table | length), failed: $failed, tail: ($text | str substring $start..) }
}
