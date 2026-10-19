const LEAVES = ['std' 'rig/sourcetrait/emptwo/prototype/long']
const FORM = '^\s*(?P<form>export use|overlay use|use|source)\s+(?P<rest>\S.*)$'
const PATH_CONST = '^(?:export )?const (?P<n>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*["''](?P<v>[^"'']*)["'']\s*$'
const SELF_CONST = '^(?:export )?const (?P<n>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*\(?path self (?P<v>[^\s\)]+)\)?\s*$'
const HERE_CONST = '^(?:export )?const (?P<n>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*\(path self \| path expand \| path dirname\)\s*$'
const JOIN_CONST = '^(?:export )?const (?P<n>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*\(\$(?P<h>[A-Za-z_][A-Za-z0-9_]*) \| path join (?P<v>\S+) \| path expand\)\s*$'

# A line's import: its form, the path it names, and the list after it.
def import-of [line: string]: nothing -> oneof<record<form: string, target: string, list: list<string>>, nothing> {
    let m = ($line | parse --regex $FORM)
    if ($m | is-empty) { return null }
    let x = ($m | first)
    let rest = ($x.rest | str trim)
    let selfpath = ($rest | parse --regex '^\(path self (?P<t>[^\s\)]+)\)(?P<tail>.*)$')
    let quoted = ($rest | parse --regex '^(?P<q>["''])(?P<t>[^"'']*)["''](?P<tail>.*)$')
    let split = (if ($selfpath | is-not-empty) {
        {target: ($selfpath | first | get t), tail: ($selfpath | first | get tail)}
    } else if ($quoted | is-not-empty) {
        {target: ($quoted | first | get t), tail: ($quoted | first | get tail)}
    } else {
        let w = ($rest | parse --regex '^(?P<t>\S+)(?P<tail>.*)$' | first)
        {target: $w.t, tail: $w.tail}
    })
    let list = ($split.tail
        | parse --regex '\[(?P<l>[^\]]*)\]'
        | get -o 0.l
        | default ''
        | split row --regex '[\s,]+'
        | where {|n| $n != '' })
    {form: $x.form, target: $split.target, list: $list}
}

# A source's imports: each its line, its form, the path it names, and its list.
export def lines-of [src: string]: nothing -> table<line: int, form: string, target: string, list: list<string>> {
    $src | lines | enumerate | each {|e|
        $e.item | split row ';' | each {|part|
            let i = (import-of $part)
            if $i != null { $i | insert line ($e.index + 1) }
        } | compact
    } | flatten
}

# A source's parse-time constants that name a path, each name to its text.
def path-consts [src: string]: nothing -> record {
    let ls = ($src | lines)
    let here = ($ls | parse --regex $HERE_CONST | get n)
    let joined = ($ls | parse --regex $JOIN_CONST | where {|c| $c.h in $here } | select n v)
    $ls | parse --regex $PATH_CONST | append ($ls | parse --regex $SELF_CONST) | append $joined
    | reduce --fold {} {|c, acc| $acc | upsert $c.n $c.v }
}

# The path an import names, a constant's text for a bound one, else null.
export def target-of [src: string, imp: record]: nothing -> oneof<string, nothing> {
    if ($imp.target | str starts-with '$') {
        path-consts $src | get -o ($imp.target | str substring 1..)
    } else { $imp.target }
}

# A refused import's resolution, with why.
def refused [why: string]: nothing -> record<kind: string, repo: string, file: string, detail: string> {
    {kind: 'refused', repo: '', file: '', detail: $why}
}

# A recipe's import: the monolith, or the module directory, its path ends
# with, the longest when two do, else unread.
def recipe-target [target: string, known: table]: [
    nothing -> record<kind: string, repo: string, file: string, detail: string>
] {
    let named = ($known
        | where {|k| ($target | str ends-with $k.file) or (($k.file | path basename) == 'mod.nu' and ($target | str ends-with ($k.file | path dirname))) }
        | sort-by {|k| $k.file | str length } --reverse)
    if ($named | is-empty) { return {kind: 'unread', repo: '', file: $target, detail: 'a path through a placeholder'} }
    {kind: 'file', repo: ($named | first | get repo), file: ($named | first | get file), detail: ''}
}

# Where an import resolves: a checkout's file, an external leaf, or a refusal.
export def resolve [roots: record, repo: string, file: string, kind: string, src: string, imp: record, monoliths: table]: [
    nothing -> record<kind: string, repo: string, file: string, detail: string>
] {
    if $imp.form == 'overlay use' { return (refused 'overlay use') }
    let target = (target-of $src $imp)
    if $target == null { return (refused $"($imp.target), no parse-time constant of a path") }
    if ($target == 'std') or ($target | str starts-with 'std/') {
        return {kind: 'leaf', repo: '', file: 'std', detail: ''}
    }
    if $target in $LEAVES {
        if $kind == 'descriptor' { return {kind: 'leaf', repo: '', file: $target, detail: ''} }
        return (refused $"($target) outside a runner's body")
    }
    if ($target | str contains '$') or ($target | str contains '(') { return (refused $"($target), built at run time") }
    if ($target | str starts-with '/') or ($target | str starts-with '~') { return (refused $"($target), absolute") }
    if $kind == 'recipe' { return (recipe-target $target $monoliths) }
    let at = ($roots | get $repo | path join $file | path dirname | path join $target | path expand)
    let found = (if ($at | path type) == 'file' {
        $at
    } else if ($at | path join 'mod.nu' | path type) == 'file' {
        $at | path join 'mod.nu'
    } else { null })
    if $found == null { return (refused $"($target), no file or module there") }
    let owner = ($roots | transpose repo root | where {|r| $found | str starts-with ($r.root + '/') } | get -o 0)
    if $owner == null { return (refused $"($target), outside both checkouts") }
    {kind: 'file', repo: $owner.repo, file: ($found | path relative-to $owner.root), detail: ''}
}

# The files on a cycle of imports, each as its checkout and path.
export def cycles-of [edges: table<from: string, to: string>]: nothing -> list<string> {
    let nodes = ($edges | get from | append ($edges | get to) | uniq)
    let next = ($edges | group-by from | transpose node rows
        | reduce --fold {} {|g, acc| $acc | upsert $g.node ($g.rows | get to | uniq) })
    mut on = []
    for n in $nodes {
        mut seen = []
        mut todo = ($next | get -o $n | default [])
        while ($todo | is-not-empty) {
            let y = ($todo | first)
            $todo = ($todo | skip 1)
            if $y in $seen { continue }
            $seen = ($seen | append $y)
            $todo = ($todo | append ($next | get -o $y | default []))
        }
        if $n in $seen { $on = ($on | append $n) }
    }
    $on
}
