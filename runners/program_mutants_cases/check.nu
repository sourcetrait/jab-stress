# The mutant runners' cases checked as a consumer ran them: every case's
# saved log begins with its canned log, and its recorded exit is the canned
# status, 1 when the canned log holds nushell's error and 0 otherwise.
#
# Usage: nu check.nu <logs> <results.nuon>
#
# <logs> is the run's `logs` directory and <results.nuon> the run's
# `results`, a table holding at least each case's `name` and `exit`; the
# canned logs are this directory's `logs/`. Exits 1 naming every case that
# did not run as canned.
def main [logs: path, results: path] {
    let canned_dir = ($env.FILE_PWD | path join "logs")
    let names = (glob ($canned_dir | path join "*.log") | each {|p| $p | path parse | get stem } | sort)
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
