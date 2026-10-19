# The reading's file new under `base`
export def ready [a: record]: nothing -> record {
    let out = ($a.base | path join "census.nuon")
    if ($out | path exists) { error make { msg: $"the reading exists: ($out)" } }
    {}
}

# The tile census read over the batches by its bin, its problems counted
export def main [a: record]: nothing -> record {
    let out = ($a.base | path join "census.nuon")
    let r = (^$nu.current-exe $a.nuance $a.base $out ...$a.labels | complete)
    ($r.stdout + $r.stderr) | save --raw -f ($a.base | path join "census_reread.log")
    if $r.exit_code != 0 { error make { msg: $"the reader exited ($r.exit_code): (($r.stdout + $r.stderr) | lines | last 8 | str join ' | ' | str substring 0..900)" } }
    { exit: $r.exit_code, problems: (open $out | get problems | length) }
}
