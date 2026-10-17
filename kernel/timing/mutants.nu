# The selector's mutants (TimingSelector), each a rule of select.nu
# removed and to fail at its own hold. Each mutant edits a copy of
# select.nu under the scratch and runs that copy's holds there; a control,
# the copy unedited, runs first and must pass. A mutant is caught when
# its run fails and its failure, the raised line, names its expect, the
# hold `timing holds: <expect>:`; applied when its every find matched
# exactly once. The set is a NUON table of name, expect, and edits of
# file, find, and put, the file relative to this repository. The results
# land in the scratch as results.nuon.

def main [
    set: path                      # the mutant set, selector_mutants.nuon
    scratch: path                  # a directory the call makes
    --only: string = ""            # the mutants to run, comma separated, every one unless given
] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    let only = (if $only == "" { [] } else { $only | split row "," | each {|n| $n | str trim } })
    let here = $env.FILE_PWD
    let mutants = (open --raw $set | decode | from nuon)
    let unknown = ($only | where {|n| $n not-in ($mutants | get name) })
    if not ($unknown | is-empty) { error make { msg: $"no such mutant: ($unknown | str join ', ')" } }
    let chosen = (if ($only | is-empty) { $mutants } else { $mutants | where {|m| $m.name in $only } })
    mkdir $scratch
    let source = (open --raw ($here | path join "select.nu") | decode)
    let jobs = ([{ name: "control", expect: "", edits: [] }] | append $chosen)
    mut rows = []
    for m in $jobs {
        let t0 = (date now)
        let text = (applied $source ($m.edits | where {|e| $e.file == "kernel/timing/select.nu" }))
        if $text == null or ($m.edits | any {|e| $e.file != "kernel/timing/select.nu" }) {
            $rows = ($rows | append { name: $m.name, class: "unapplied", title: "a find does not match exactly once, or names another file", seconds: 0 })
            continue
        }
        let dir = ($scratch | path join $m.name)
        mkdir $dir
        $text | save --raw ($dir | path join "select.nu")
        let r = (^nu ($dir | path join "select.nu") holds ($dir | path join "holds") | complete)
        let out = ($r.stdout + $r.stderr)
        $out | save --raw ($dir | path join "holds.log")
        let title = (raised-line $out "timing holds: ")
        let class = (if $m.name == "control" {
            if $r.exit_code == 0 and ($r.stdout | lines | any {|l| $l == "timing holds: ok" }) { "passed" } else { "failed" }
        } else if $r.exit_code != 0 and ($title | str contains $"timing holds: ($m.expect):") { "caught" } else { "missed" })
        $rows = ($rows | append { name: $m.name, class: $class, title: $title, seconds: (((date now) - $t0) / 1sec | math round) })
    }
    let results = {
        set: ($set | path expand),
        set_sha256: (open --raw $set | hash sha256),
        selector_sha256: ($source | hash sha256),
        control: ($rows | where name == "control" | first),
        results: ($rows | where name != "control"),
        every: ($rows | all {|r| if $r.name == "control" { $r.class == "passed" } else { $r.class == "caught" } }),
    }
    $results | to nuon --indent 1 | save --raw ($scratch | path join "results.nuon")
    for r in $rows { print $"timing mutants: ($r.name): ($r.class), ($r.title)" }
    print $"timing mutants: (if $results.every { 'every one caught' } else { 'not every one caught' })"
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
