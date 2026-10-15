# The mutant runners' cases checked as a consumer ran them: every case's
# saved log begins with its canned log, and its recorded exit is the canned
# status, 1 when the canned log holds nushell's error and 0 otherwise.
#
# Usage: nu check.nu <logs> <results.nuon> [--data <checkout>]
#
# <logs> is the run's `logs` directory and <results.nuon> the run's
# `results`, a table holding at least each case's `name` and `exit`. The
# canned logs are asset data: `assets/workbench/cases/logs/` in the data
# checkout beside this repository, `../jab-stress-data`, or in the one
# --data names. The inventory comes from the case list, this directory's
# cases.nuon: a `<name>.log` for each of its cases and `control.log`.
# Before any result is read, the check refuses when the data checkout is
# missing, when a log the list names is missing, and when the directory
# holds a log the list does not name. Exits 1 naming every case that did
# not run as canned.
def main [logs: path, results: path, --data: path] {
    let given = (if $data == null { $env.FILE_PWD | path join ".." ".." ".." "jab-stress-data" } else { $data })
    let checkout = ($given | path expand)
    if ($checkout | path type) != "dir" {
        error make {msg: $"no data checkout at ($checkout); the canned logs are its assets/workbench/cases/logs/"}
    }
    let canned_dir = ($checkout | path join "assets" "workbench" "cases" "logs")
    if ($canned_dir | path type) != "dir" {
        error make {msg: $"the data checkout at ($checkout) holds no assets/workbench/cases/logs/"}
    }
    let names = (open ($env.FILE_PWD | path join "cases.nuon") | get name | append "control" | sort)
    let present = (glob ($canned_dir | path join "*.log") | each {|p| $p | path parse | get stem } | sort)
    let missing = ($names | where {|n| $n not-in $present })
    if not ($missing | is-empty) {
        error make {msg: $"($canned_dir) lacks the case list's ($missing | each {|n| $'($n).log' } | str join ', ')"}
    }
    let unlisted = ($present | where {|n| $n not-in $names })
    if not ($unlisted | is-empty) {
        error make {msg: $"($canned_dir) holds ($unlisted | each {|n| $'($n).log' } | str join ', '), which the case list does not name"}
    }
    let rows = (open $results)
    mut problems = []
    for n in $names {
        let canned = (open --raw ($canned_dir | path join $"($n).log") | decode)
        let status = (if ($canned | str contains "Error: ") { 1 } else { 0 })
        let saved = ($logs | path join $"($n).log")
        if ($saved | path type) != "file" {
            $problems = ($problems | append $"($n): no saved log")
        } else if not (open --raw $saved | decode | str starts-with $canned) {
            $problems = ($problems | append $"($n): its saved log is not its canned one")
        }
        let row = ($rows | where name == $n)
        if ($row | is-empty) {
            $problems = ($problems | append $"($n): no result")
        } else if ($row | get 0.exit) != $status {
            $problems = ($problems | append $"($n): exit ($row | get 0.exit), its canned status ($status)")
        }
    }
    for n in ($rows | get name | where {|x| $x not-in $names }) {
        $problems = ($problems | append $"($n): a result with no canned log")
    }
    if not ($problems | is-empty) {
        error make {msg: $"the cases did not run as canned: ($problems | str join '; ')"}
    }
    print $"cases: ($names | length) ran as canned"
}
