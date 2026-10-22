# The series checked before its launch, its base made
export def ready [a: record]: nothing -> record {
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a series is written once" } }
    let twice = ($a.runs | get label | uniq --repeated)
    if ($twice | is-not-empty) { error make { msg: $"a label twice: ($twice | str join ', ')" } }
    if ($a.probe_dir | path basename) != "probe" { error make { msg: $"($a.probe_dir) is not a probe's directory" } }
    mkdir $a.base
    $a.runs | to nuon --indent 2 | save --raw ($a.base | path join "runs.nuon")
    {}
}

# Each run's sdl probe of the program in order, its directory and record kept
export def main [a: record]: nothing -> record {
    mut done = []
    for r in $a.runs {
        let dir = ($a.base | path join $r.label)
        mkdir $dir
        cd $a.jab
        let p = (^$nu.current-exe ($a.jab | path join nu bin nuance probe.nu) sdl $a.program ...$r.words | complete)
        $p.stdout | save --raw ($dir | path join "record.nuon")
        $p.stderr | save --raw ($dir | path join "probe.err")
        if $p.exit_code != 0 { error make { msg: $"($r.label) exited ($p.exit_code): ($p.stderr | lines | last 6 | str join ' | ' | str substring 0..900)" } }
        cp -r $a.probe_dir ($dir | path join "probe")
        $done = ($done | append $r.label)
    }
    { runs: $done }
}
