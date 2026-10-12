# The cases as the checkout runner (runners/checkout_mutants.nuon) reads
# them: a scratch checkout at <dir> holding `case`, its whole text
# `control`; a justfile whose `test cases` prints the canned log `case`
# names, from this directory's logs/, and exits 1 when it holds nushell's
# error, else 0; and `set.nuon`, cases.nuon's cases as a mutant set of the
# one program `cases`, each one edit making `case` its own name, with its
# `expect` and `class`. Every case's run so exercises the runner's finds
# and its restore.
#
# Usage: nu checkout.nu <dir>
#
# <dir> must not exist. The runner then takes `jab` <dir>, `set`
# <dir>/set.nuon, `only` every case's name, and `control` {program: cases,
# ok: "eviction reuse: ok"}, the canned control log its passing run.
def main [dir: path] {
    if ($dir | path type) != null { error make {msg: $"($dir) exists; a scratch checkout starts empty"} }
    let logs = ($env.FILE_PWD | path join "logs")
    if ($logs | str contains "'") { error make {msg: $"($logs) holds a quote the justfile cannot carry"} }
    let recipe = r#'    if '{{program}}' != 'cases' { print -e 'cases is the one program here'; exit 2 }; let log = (open --raw ('{{logs}}' | path join $"(open --raw ('{{justfile_directory()}}' | path join case) | decode).log") | decode); print -n $log; exit (if ($log | str contains "Error: ") { 1 } else { 0 })'#
    let justfile = [
        "# The checkout runner's scratch checkout, written by checkout.nu: `test"
        "# cases` prints the canned log the file `case` names and exits 1 when it"
        "# holds nushell's error, else 0."
        ""
        'set shell := ["nu", "-c"]'
        "set quiet := true"
        ""
        $"logs := '($logs)'"
        ""
        "test program:"
        $recipe
        ""
    ]
    let set = (open ($env.FILE_PWD | path join "cases.nuon") | each {|c|
        { name: $c.name, program: "cases", expect: $c.expect, class: $c.class, edits: [{ file: "case", find: "control", put: $c.name }] }
    })
    mkdir $dir
    "control" | save --raw ($dir | path join "case")
    $justfile | str join (char nl) | save --raw ($dir | path join "justfile")
    $set | to nuon --indent 2 | save --raw ($dir | path join "set.nuon")
    print $"checkout: ($dir), ($set | length) cases in its set.nuon"
}
