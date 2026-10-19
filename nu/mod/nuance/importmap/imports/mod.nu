const LEAVES = ['std' 'rig/sourcetrait/emptwo/prototype/long']
const FORM = '^\s*(?P<form>export use|overlay use|use|source)\s+(?P<rest>\S.*)$'
const PATH_CONST = '^(?:export )?const (?P<n>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*["''](?P<v>[^"'']*)["'']\s*$'

# A line's import: its form, the path it names, and the list after it.
def import-of [line: string]: nothing -> oneof<record<form: string, target: string, list: list<string>>, nothing> {
    let m = ($line | parse --regex $FORM)
    if ($m | is-empty) { return null }
    let x = ($m | first)
    let rest = ($x.rest | str trim)
    let quoted = ($rest | parse --regex '^(?P<q>["''])(?P<t>[^"'']*)["''](?P<tail>.*)$')
    let split = (if ($quoted | is-not-empty) {
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
        let i = (import-of $e.item)
        if $i != null { $i | insert line ($e.index + 1) }
    } | compact
}

# A source's parse-time constants that name a path, each name to its text.
def path-consts [src: string]: nothing -> record {
    $src | lines | parse --regex $PATH_CONST | reduce --fold {} {|c, acc| $acc | upsert $c.n $c.v }
}

# A refused import's resolution, with why.
def refused [why: string]: nothing -> record<kind: string, repo: string, file: string, detail: string> {
    {kind: 'refused', repo: '', file: '', detail: $why}
}

# A recipe's import: the monolith its path ends with, else unread.
def recipe-target [target: string, monoliths: table]: [
    nothing -> record<kind: string, repo: string, file: string, detail: string>
] {
    let named = ($monoliths | where {|k| $target | str ends-with $k.file })
    if ($named | is-empty) { return {kind: 'unread', repo: '', file: $target, detail: 'a path through a placeholder'} }
    {kind: 'file', repo: ($named | first | get repo), file: ($named | first | get file), detail: ''}
}

# Where an import resolves: a checkout's file, an external leaf, or a refusal.
export def resolve [roots: record, repo: string, file: string, kind: string, src: string, imp: record, monoliths: table]: [
    nothing -> record<kind: string, repo: string, file: string, detail: string>
] {
    if $imp.form == 'overlay use' { return (refused 'overlay use') }
    let target = (if ($imp.target | str starts-with '$') {
        path-consts $src | get -o ($imp.target | str substring 1..)
    } else { $imp.target })
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
