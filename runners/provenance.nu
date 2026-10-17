# Whether a mutant runner's failure is an assertion's own: the provenance
# rule the program runner, the census runner, and the gauge titles reader
# share. Import it by its absolute path, `use <checkout>/runners/
# provenance.nu [failure-of assertion-kind]`, then read a log's lines:
# `failure-of` gives the first error's title, and `assertion-kind` names
# the assertion that error is the failure of, or null.

# The most lines of an excerpt read for its closing `----.
const EXCERPT_LINES = 200

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
# block's brace or a semicolon, and the labels bound to that line are the
# assertion's own, `It is not true.`, or `left:` and `right:` under a
# title closing `These are not equal.`; null for any other failure. The
# excerpt runs from the header to its closing `----, which must come
# within EXCERPT_LINES, each of its lines a source line (`NN |`), a label
# line (`:`), or neither. A one-line assertion's labels are the label
# lines right under its line, each hanging from `-- or, a label whose
# value runs across lines, from `-|. An assertion whose argument spans
# lines puts a four-column gutter on every source line of the excerpt,
# `,-> ` on the span's first, `|   ` inside it, `|-> ` on its last: the
# four columns are stripped from the line read, the header's line must
# open the span, and its labels are every label line from there through
# the first source line past the span's close, each hanging from `--,
# `-|, or, under the span's last line, `----.
export def assertion-kind [ls: list<string>, failure: record<title: string, after: int>] {
    if $failure.after < 0 { return null }
    let header = ($ls | get -o $failure.after | default "" | parse --regex '^\s*,-\[(?P<file>.+):(?P<line>\d+):(?P<col>\d+)\]$' | get -o 0)
    if $header == null { return null }
    let read = ($ls | skip ($failure.after + 1) | first $EXCERPT_LINES)
    let closing = ($read | enumerate | where {|e| $e.item =~ '^\s*`----' } | get -o 0.index)
    if $closing == null { return null }
    let excerpt = ($read | first $closing)
    let lines = ($excerpt | each {|l|
        let s = ($l | parse --regex '^\s*(?P<n>\d+) \| ?(?P<code>.*)$' | get -o 0)
        if $s != null { {kind: "source", n: $s.n, code: $s.code} } else if ($l =~ '^\s*:') { {kind: "label", n: null, code: $l} } else { {kind: "other", n: null, code: $l} }
    })
    let at = ($lines | enumerate | where {|e| $e.item.kind == "source" and $e.item.n == $header.line } | get -o 0.index)
    if $at == null { return null }
    let opening = ($lines | get $at)
    let spanned = ($lines | any {|e| $e.kind == "source" and ($e.code | str starts-with ",-> ") })
    if $spanned and not ($opening.code | str starts-with ",-> ") { return null }
    let code = (if $spanned { $opening.code | str substring 4.. } else { $opening.code })
    let head = ($code | str substring 0..<(($header.col | into int) - 1))
    let kind = ($head | parse --regex '(?:^|[{;])\s*(?P<kind>assert(?: equal)?) $' | get -o 0.kind)
    if $kind == null { return null }
    let after = ($lines | skip ($at + 1))
    let labels = (if $spanned {
        let close = ($after | enumerate | where {|e| $e.item.kind == "source" and ($e.item.code | str starts-with "|-> ") } | get -o 0.index)
        if $close == null { return null }
        let past = ($after | skip ($close + 1) | enumerate | where {|e| $e.item.kind == "source" } | get -o 0.index)
        let bound = (if $past == null { $after | length } else { $close + 1 + $past })
        $after | first $bound | where {|e| $e.kind == "label" } | get code
    } else {
        $after | take while {|e| $e.kind == "label" } | get code
    })
    let connector = (if $spanned { '`(?:-[-|]|----) ' } else { '`-[-|] ' })
    let own = (if $kind == "assert" {
        $labels | any {|l| $l =~ ($connector + 'It is not true\.') }
    } else {
        ($labels | any {|l| $l =~ ($connector + 'left:') }) and ($labels | any {|l| $l =~ ($connector + 'right:') }) and ($failure.title | str ends-with "These are not equal.")
    })
    if $own { $kind } else { null }
}
