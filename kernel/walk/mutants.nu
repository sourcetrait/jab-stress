# walk's CADENCE mutants (WalkCadence), each to fail at its own case. A
# reader mutant edits a copy of cadence.nu under the scratch and runs that
# copy's holds there, the Jab checkout linked beside it as the reader's
# own `use` finds it. A program mutant edits example/walk/src/main.S in
# the Jab checkout, runs walk's launches on the cases it names, and puts
# the file back as HEAD holds it before the next, the checkout's file
# required to match HEAD before any is written. A control runs first for
# each kind: the holds on an unedited copy, the launches on every case
# the program mutants name. A mutant is caught when its run fails and its
# failure, the raised line, names its expect; applied when its every find
# matched exactly once. The set is a NUON table of name, kind (reader or
# program), cases (a program mutant's), expect, and edits of file, find,
# and put, a reader's file relative to this repository and a program's to
# the Jab checkout. The results land in the scratch as results.nuon.
const HEAD_PREFIX = "HEAD:"

def main [
    jab_dir: path                  # the Jab checkout, clean at HEAD where a program mutant writes
    set: path                      # the mutant set, walk_mutants.nuon
    scratch: path                  # a directory the call makes
    --only: string = ""            # the mutants to run, comma separated, every one unless given
] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    let only = (if $only == "" { [] } else { $only | split row "," | each {|n| $n | str trim } })
    let jab = ($jab_dir | path expand)
    let here = $env.FILE_PWD
    let mutants = (open --raw $set | decode | from nuon)
    let unknown = ($only | where {|n| $n not-in ($mutants | get name) })
    if not ($unknown | is-empty) { error make { msg: $"no such mutant: ($unknown | str join ', ')" } }
    let chosen = (if ($only | is-empty) { $mutants } else { $mutants | where {|m| $m.name in $only } })
    mkdir $scratch
    let readers = ($chosen | where kind == "reader")
    let programs = ($chosen | where kind == "program")
    let reader_rows = (if ($readers | is-empty) { [] } else { reader-runs $here $jab ($scratch | path join "reader") $readers })
    let program_rows = (if ($programs | is-empty) { [] } else { program-runs $here $jab ($scratch | path join "program") $programs })
    let rows = ($reader_rows ++ $program_rows)
    let results = {
        set: ($set | path expand),
        set_sha256: (open --raw $set | hash sha256),
        jab_head: (^git -C $jab rev-parse HEAD | str trim),
        controls: ($rows | where name == "control" | select kind class title),
        results: ($rows | where name != "control"),
        every: ($rows | all {|r| if $r.name == "control" { $r.class == "passed" } else { $r.class == "caught" } }),
    }
    $results | to nuon --indent 1 | save --raw ($scratch | path join "results.nuon")
    for r in $rows { print $"walk mutants: ($r.kind) ($r.name): ($r.class), ($r.title)" }
    print $"walk mutants: (if $results.every { 'every one caught' } else { 'not every one caught' })"
    if not $results.every { exit 1 }
}

# The text with each edit applied, its find exactly once; null with a
# find that does not match exactly once.
def applied [text: string, edits: list<record>]: nothing -> any {
    mut t = $text
    for e in $edits {
        let n = (($t | split row $e.find | length) - 1)
        if $n != 1 { return null }
        $t = ($t | str replace $e.find $e.put)
    }
    $t
}

# A run's failure: the raised message naming the head, the last such, its
# lines as nushell wraps them joined back into one; empty for none.
def raised-line [text: string, head: string]: nothing -> string {
    let ls = ($text | lines)
    let starts = ($ls | enumerate | where {|r| let t = ($r.item | str trim); ($t | str contains $head) and ($t =~ '^(x|×) ') })
    if ($starts | is-empty) { return "" }
    let i = ($starts | last | get index)
    let first = ($ls | get $i | str trim | str replace --regex '^(x|×) ' '')
    let rest = ($ls | skip ($i + 1) | take while {|l| ($l | str trim) starts-with "|" } | each {|l| $l | str trim | str replace --regex '^\| ?' '' })
    [$first] ++ $rest | str join " " | str substring 0..400
}

def reader-runs [here: path, jab: path, scratch: path, mutants: list<record>]: nothing -> list<record> {
    mkdir $scratch
    ^ln -s $jab ($scratch | path join "jab")
    let source = (open --raw ($here | path join "cadence.nu") | decode)
    let jobs = ([{ name: "control", kind: "reader", expect: "", edits: [] }] | append $mutants)
    $jobs | each {|m|
        let t0 = (date now)
        let text = (applied $source $m.edits)
        if $text == null { return { name: $m.name, kind: "reader", class: "unapplied", title: "a find does not match exactly once", seconds: 0 } }
        let dir = ($scratch | path join $m.name "kernel" "walk")
        mkdir $dir
        $text | save --raw ($dir | path join "cadence.nu")
        let r = (^nu ($dir | path join "cadence.nu") holds ($scratch | path join $m.name "holds") | complete)
        let out = ($r.stdout + $r.stderr)
        $out | save --raw ($scratch | path join $m.name "holds.log")
        let title = (raised-line $out "cadence holds: ")
        let class = (if $m.name == "control" {
            if $r.exit_code == 0 and ($r.stdout | lines | any {|l| $l == "cadence holds: ok" }) { "passed" } else { "failed" }
        } else if $r.exit_code != 0 and ($title | str contains $"cadence holds: ($m.expect):") { "caught" } else { "missed" })
        { name: $m.name, kind: "reader", class: $class, title: $title, seconds: (((date now) - $t0) / 1sec | math round) }
    }
}

def program-runs [here: path, jab: path, scratch: path, mutants: list<record>]: nothing -> list<record> {
    let files = ($mutants | each {|m| $m.edits | get file } | flatten | uniq)
    let heads = ($files | each {|f|
        let head = (^git -C $jab show $"($HEAD_PREFIX)($f)" | complete)
        if $head.exit_code != 0 { error make { msg: $"walk mutants: ($f) is not at HEAD: ($head.stderr | str trim)" } }
        let now = (open --raw ($jab | path join $f) | decode)
        if $now != $head.stdout { error make { msg: $"walk mutants: ($f) differs from HEAD; a program mutant writes there only on a clean file" } }
        { file: $f, text: $head.stdout }
    })
    let cases = ($mutants | get cases | flatten | uniq)
    let launches = ($here | path join "launches.nu")
    mkdir $scratch
    let jobs = ([{ name: "control", kind: "program", cases: $cases, expect: "", edits: [] }] | append $mutants)
    $jobs | each {|m|
        let t0 = (date now)
        let writes = ($heads | each {|h| { file: $h.file, text: (applied $h.text ($m.edits | where file == $h.file)) } })
        if ($writes | any {|w| $w.text == null }) { return { name: $m.name, kind: "program", class: "unapplied", title: "a find does not match exactly once", seconds: 0 } }
        for w in $writes { $w.text | save --raw -f ($jab | path join $w.file) }
        let r = (try { ^nu $launches $jab ($scratch | path join $m.name) --only ($m.cases | str join ",") | complete } catch {|e| { exit_code: -1, stdout: "", stderr: $e.msg } })
        for h in $heads { $h.text | save --raw -f ($jab | path join $h.file) }
        let back = ($heads | all {|h| (open --raw ($jab | path join $h.file) | decode) == $h.text })
        if not $back { error make { msg: "walk mutants: a file did not go back to HEAD; restore it before anything else" } }
        let out = ($r.stdout + $r.stderr)
        $out | save --raw ($scratch | path join $"($m.name).log")
        let title = (raised-line $out "walk launches: ")
        let class = (if $m.name == "control" {
            if $r.exit_code == 0 and ($r.stdout | lines | any {|l| $l == "walk launches: ok" }) { "passed" } else { "failed" }
        } else if $r.exit_code != 0 and ($title | str contains $m.expect) { "caught" } else { "missed" })
        { name: $m.name, kind: "program", class: $class, title: $title, seconds: (((date now) - $t0) / 1sec | math round) }
    }
}
