# Whether a mutant runner's failure is an assertion's own: the provenance
# rule the program runner, the census runner, and the gauge titles reader
# share. Import it by its absolute path, `use <checkout>/runners/
# provenance.nu [failure-of assertion-kind]`, then read a log's lines:
# `failure-of` gives the first error's title, and `assertion-kind` names
# the assertion that error is the failure of, or null.

# The log's first error: its title, the `  x ` line with its `  | `
# continuations joined, and the index of the line after them.
export def failure-of [ls: list<string>]: nothing -> record<title: string, after: int> {
    let start = ($ls | enumerate | where {|e| $e.item starts-with "  x " } | get -o 0.index)
    if $start == null { return {title: "", after: -1} }
    let more = ($ls | skip ($start + 1) | take while {|l| $l starts-with "  | " })
    {
        title: ([($ls | get $start | str substring 4..)] | append ($more | each {|l| $l | str substring 4.. }) | str join " "),
        after: ($start + 1 + ($more | length)),
    }
}

# The assertion whose own failure the error is: `assert` or `assert equal`
# when the header right after its title names an excerpt line whose code
# up to the header's column is that assertion's head, alone or after a
# block's brace or a semicolon, and the labels under that line are the
# assertion's own, `It is not true.`, or `left:` and `right:` under a
# title closing `These are not equal.`, each hanging from `-- or, a label
# whose value runs across lines, from `-|; null for any other failure.
export def assertion-kind [ls: list<string>, failure: record<title: string, after: int>] {
    if $failure.after < 0 { return null }
    let header = ($ls | get -o $failure.after | default "" | parse --regex '^\s*,-\[(?P<file>.+):(?P<line>\d+):(?P<col>\d+)\]$' | get -o 0)
    if $header == null { return null }
    let excerpt = ($ls | skip ($failure.after + 1) | take until {|l| $l =~ '^\s*`----' })
    let at = ($excerpt | enumerate | where {|e| ($e.item | parse --regex '^\s*(?P<n>\d+) \|' | get -o 0.n) == $header.line } | get -o 0.index)
    if $at == null { return null }
    let code = ($excerpt | get $at | parse --regex '^\s*\d+ \| ?(?P<code>.*)$' | get 0.code)
    let head = ($code | str substring 0..<(($header.col | into int) - 1))
    let kind = ($head | parse --regex '(?:^|[{;])\s*(?P<kind>assert(?: equal)?) $' | get -o 0.kind)
    if $kind == null { return null }
    let labels = ($excerpt | skip ($at + 1) | take while {|l| $l =~ '^\s*:' })
    let own = (if $kind == "assert" {
        $labels | any {|l| $l =~ '`-[-|] It is not true\.' }
    } else {
        ($labels | any {|l| $l =~ '`-[-|] left:' }) and ($labels | any {|l| $l =~ '`-[-|] right:' }) and ($failure.title | str ends-with "These are not equal.")
    })
    if $own { $kind } else { null }
}
