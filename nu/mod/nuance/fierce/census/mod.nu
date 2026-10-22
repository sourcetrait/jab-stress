# The census reader's holds over a serial log by a jab tree's census module
export def reader-holds [tree: path, serial: path]: nothing -> any {
    let census = ($tree | path join kit fierce nu mod census)
    ^$nu.current-exe -c $"use ($census | to nuon) [census-reader-holds]; census-reader-holds \(open --raw ($serial | to nuon) | decode\); print 'reader-holds: ok'"
}
