# jab, checked out beside the workbench
const JAB = (path self ../../../../../../jab | path expand)

# The census reader's holds over a serial log by a jab tree's census module
export def reader-holds [tree: path, serial: path] {
    let census = ($tree | path join kit fierce nu mod census)
    ^$nu.current-exe -c $"use ($census | to nuon) [census-reader-holds]; census-reader-holds \(open --raw ($serial | to nuon) | decode\); print 'reader-holds: ok'"
}

# fierce's gauge module loaded alone in a nu of its own
export def gauge-load [] {
    let gauge = ($JAB | path join kit fierce nu mod gauge)
    ^$nu.current-exe -c $"use ($gauge | to nuon); print 'loaded'"
}
