# Nothing to make before the launch
export def ready [a: record]: nothing -> record {
    {}
}

# fierce's development smoke by its bin, the log saved, its telling lines kept
export def main [a: record]: nothing -> record {
    let r = (^$nu.current-exe $a.nuance smoke $a.seeds $a.seconds | complete)
    ($r.stdout + $r.stderr) | save --raw -f $a.log
    let tail = ($r.stdout + $r.stderr | lines | where {|l| $l =~ '^smoke|rror|assert|FAULT' } | last 8)
    if $r.exit_code != 0 { error make { msg: $"smoke exited ($r.exit_code): ($tail | str join ' | ')" } }
    { exit: $r.exit_code, tail: $tail }
}
