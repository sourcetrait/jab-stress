# The battery's base new, its labels distinct, walk's wrapper there; the base made, its batches kept
export def ready [a: record]: nothing -> record {
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a battery is written once" } }
    let twice = ($a.batches | get label | uniq --repeated)
    if ($twice | is-not-empty) { error make { msg: $"a label twice: ($twice | str join ', ')" } }
    let wrapper = ($a.jab | path join example walk test cadence.nu)
    if not ($wrapper | path exists) { error make { msg: $"($a.jab) holds no walk wrapper at example/walk/test/cadence.nu" } }
    mkdir $a.base
    $a.batches | to nuon --indent 2 | save --raw ($a.base | path join "batches.nuon")
    {}
}

# Each batch's runs through walk's wrapper in order, each batch's output logged
export def main [a: record]: nothing -> record {
    let wrapper = ($a.jab | path join example walk test cadence.nu)
    mut done = []
    for b in $a.batches {
        mut said = []
        for n in 1..$b.runs {
            cd $a.jab
            let r = (^$nu.current-exe $wrapper $b.image $b.kernel --spec $b.spec --out ($a.base | path join $b.label $"run_($n)") --label $b.label | complete)
            $said = ($said | append ($r.stdout + $r.stderr))
            if $r.exit_code != 0 {
                $said | str join "" | save --raw -f ($a.base | path join $"($b.label).log")
                error make { msg: $"($b.label) run ($n) exited ($r.exit_code): ($r.stdout + $r.stderr | lines | last 6 | str join ' | ' | str substring 0..900)" }
            }
        }
        $said | str join "" | save --raw -f ($a.base | path join $"($b.label).log")
        $done = ($done | append $b.label)
    }
    { batches: $done }
}
