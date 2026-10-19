# fierce built for the tree, then its gauge run, both outputs one log's text
def measured [fps: path, tree: string, runs: int, flags: list<string>]: nothing -> record<exit: int, text: string> {
    cd $fps
    let bin = ($fps | path join nu bin)
    let built = (^$nu.current-exe ($bin | path join do.nu) build --set (if $tree == "debug" { "debug" } else { "" }) | complete)
    if $built.exit_code != 0 { return { exit: $built.exit_code, text: ($built.stdout + $built.stderr) } }
    let ran = (^$nu.current-exe ($bin | path join nuance.nu) gauge run --tree $tree --runs $runs ...$flags | complete)
    { exit: $ran.exit_code, text: ($built.stdout + $ran.stdout + $built.stderr + $ran.stderr) }
}

# One batch measured under `base`, its log beside it, a failure its last lines
export def batch [fps: path, base: path, label: string, tree: string, runs: int, flags: list<string>, --name: string = ""] {
    let r = (measured $fps $tree $runs ($flags ++ [--out ($base | path join $label) --label $label]))
    $r.text | save --raw -f ($base | path join $"($label).log")
    let who = (if $name == "" { $label } else { $"($name) ($label)" })
    if $r.exit != 0 { error make { msg: $"($who) exited ($r.exit): ($r.text | lines | last 6 | str join ' | ' | str substring 0..900)" } }
}

# Builds' gauge.nuon compared on a field, its output saved beside, its exit kept
export def compare [fps: path, files: list<string>, field: string, base: path, --diagnostic]: nothing -> record<field: string, exit: int> {
    cd $fps
    let diag = (if $diagnostic { [--diagnostic] } else { [] })
    let c = (^$nu.current-exe ($fps | path join nu bin nuance.nu) gauge compare ...$files --field $field ...$diag --out ($base | path join $"compare_($field).nuon") | complete)
    ($c.stdout + $c.stderr) | save --raw -f ($base | path join $"compare_($field).txt")
    { field: $field, exit: $c.exit_code }
}
