const SKIP = ['.git' '.target' 'extern']
const DEF = '^(?P<exp>export )?def (?:--[a-z-]+ )*(?:"(?P<q>[^"]+)"|''(?P<s>[^'']+)''|(?P<b>[^\s\[]+))'
const CONST = '^(?P<exp>export )?const (?P<n>[A-Za-z_][A-Za-z0-9_]*)'

# Every top-level def and const of a source: its kind, name, line, and export.
export def declarations-of [src: string]: [
    nothing -> table<kind: string, name: string, line: int, exported: bool>
] {
    $src | lines | enumerate | each {|e|
        let d = ($e.item | parse --regex $DEF)
        let c = ($e.item | parse --regex $CONST)
        if ($d | is-not-empty) {
            let x = ($d | first)
            let name = (if ($x.q | is-not-empty) { $x.q } else if ($x.s | is-not-empty) { $x.s } else { $x.b })
            {kind: 'def', name: $name, line: ($e.index + 1), exported: ($x.exp | is-not-empty)}
        } else if ($c | is-not-empty) {
            let x = ($c | first)
            {kind: 'const', name: $x.n, line: ($e.index + 1), exported: ($x.exp | is-not-empty)}
        }
    } | compact
}

# A justfile's recipe bodies as nu sources, each `{{...}}` a placeholder.
def recipes-of [text: string]: nothing -> list<string> {
    mut out = []
    mut cur = []
    for l in ($text | lines) {
        if ($l =~ '^\s+\S') {
            $cur = ($cur | append ($l | str replace --all --regex '\{\{[^}]*\}\}' 'X'))
        } else if ($cur | is-not-empty) {
            $out = ($out | append ($cur | str join "\n"))
            $cur = []
        }
    }
    if ($cur | is-not-empty) { $out = ($out | append ($cur | str join "\n")) }
    $out
}

# A checkout's live sources: its nu files, its runners' bodies, and its recipes.
export def sources-of [repo: string, root: path]: [
    nothing -> table<repo: string, file: string, kind: string, src: string>
] {
    let cargo = (glob ($root | path join '**' 'Cargo.toml') --exclude ($SKIP | append 'target' | each {|d| $"**/($d)/**" })
        | each {|f| $f | path dirname | path join 'target' | path relative-to $root })
    let kept = {|f: string|
        let rel = ($f | path relative-to $root)
        not (($rel | path split | any {|p| $p in $SKIP }) or ($cargo | any {|t| $rel | str starts-with ($t + '/') }))
    }
    let pruned = ($SKIP | each {|d| $"**/($d)/**" }) ++ ($cargo | each {|t| $"**/($t)/**" })
    let nus = (glob ($root | path join '**' '*.nu') --exclude $pruned
        | where {|f| do $kept $f }
        | sort
        | each {|f| {repo: $repo, file: ($f | path relative-to $root), kind: 'nu', src: (open --raw $f | decode)} })
    let descriptors = (['runners' 'nu/nuon/runner'] | each {|d| glob ($root | path join $d '*.nuon') }
        | flatten
        | sort
        | each {|f|
            let body = (try { open $f | get body } catch { '' })
            {repo: $repo, file: ($f | path relative-to $root), kind: 'descriptor', src: $body}
        })
    let justs = ((glob ($root | path join '**' '*.just') --exclude $pruned)
        ++ (glob ($root | path join '**' 'justfile') --exclude $pruned))
    let recipes = ($justs | where {|f| do $kept $f } | sort | each {|f|
        let file = ($f | path relative-to $root)
        recipes-of (open --raw $f | decode) | each {|r| {repo: $repo, file: $file, kind: 'recipe', src: $r} }
    } | flatten)
    $nus | append $descriptors | append $recipes
}

# A scalar shape's name as nushell writes it in a signature.
def scalar-text [s: string]: nothing -> string {
    match $s {
        'Any' => 'any', 'Binary' => 'binary', 'Block' => 'block', 'Boolean' => 'bool', 'Bool' => 'bool',
        'CellPath' => 'cell-path', 'DateTime' => 'datetime', 'Date' => 'datetime',
        'Directory' => 'directory', 'Duration' => 'duration', 'Error' => 'error', 'Filepath' => 'path',
        'Filesize' => 'filesize', 'Float' => 'float', 'GlobPattern' => 'glob', 'Glob' => 'glob',
        'Int' => 'int', 'Nothing' => 'nothing', 'Number' => 'number', 'Range' => 'range',
        'String' => 'string', 'Closure' => 'closure',
        _ => ($s | str lowercase)
    }
}

# A record's or a table's fields as nushell writes them.
def fields-text [fields: list<any>]: nothing -> string {
    $fields | each {|f| $"($f.0): (shape-text $f.1)" } | str join ', '
}

# A parsed shape or type as nushell writes it.
def shape-text [s: any]: nothing -> string {
    if $s == null { return 'any' }
    if ($s | describe) == 'string' { return (scalar-text $s) }
    let k = ($s | columns | first)
    let v = ($s | get $k)
    match $k {
        'List' => $"list<(shape-text $v)>",
        'OneOf' => $"oneof<($v | each {|x| shape-text $x } | str join ', ')>",
        'Record' => (if ($v | is-empty) { 'record' } else { $"record<(fields-text $v)>" }),
        'Table' => (if ($v | is-empty) { 'table' } else { $"table<(fields-text $v)>" }),
        'Closure' => 'closure',
        'Custom' => ($v | to text),
        'CompleterWrapper' => (shape-text ($v | get 0)),
        _ => ($k | str lowercase)
    }
}

# A default value as its source wrote it, a duration or a size by its value.
def dv-text [dv: any]: nothing -> string {
    let k = (try { $dv | columns | first } catch { '' })
    if $k == 'Duration' { return ($dv.Duration.val * 1ns | to nuon) }
    if $k == 'Filesize' { return ($dv.Filesize.val * 1b | to nuon) }
    try { $dv | values | first | get span.span_source } catch { $dv | to nuon }
}

# A parameter as a signature writes it, its shape left out when any.
def param-text [name: string, shape: any]: nothing -> string {
    let st = (shape-text $shape)
    if $st == 'any' { $name } else { $"($name): ($st)" }
}

# A def's signature from its parsed form, comments dropped.
def sig-text [sg: record]: nothing -> string {
    mut ps = []
    for p in $sg.required_positional { $ps = ($ps | append (param-text $p.name $p.shape)) }
    for p in $sg.optional_positional {
        let named = (if $p.default_value != null { $p.name } else { $"($p.name)?" })
        let base = (param-text $named $p.shape)
        $ps = ($ps | append (if $p.default_value != null { $"($base) = (dv-text $p.default_value)" } else { $base }))
    }
    if $sg.rest_positional != null {
        $ps = ($ps | append (param-text $"...($sg.rest_positional.name)" $sg.rest_positional.shape))
    }
    for f in $sg.named {
        if $f.long == 'help' { continue }
        mut s = $"--($f.long)"
        if $f.short != null { $s = $"($s) \(-($f.short)\)" }
        if $f.arg != null { $s = $"($s): (shape-text $f.arg)" }
        if $f.default_value != null { $s = $"($s) = (dv-text $f.default_value)" }
        $ps = ($ps | append $s)
    }
    let io = ($sg.input_output_types | each {|pr| $"(shape-text $pr.0) -> (shape-text $pr.1)" })
    let iot = (if ($io | is-empty) {
        ''
    } else if ($io | length) == 1 {
        $": ($io | first)"
    } else {
        $": [($io | str join ', ')]"
    })
    $"[($ps | str join ', ')]($iot)"
}

# Every top-level def's signature in a source, keyed by its name.
export def signatures-of [src: string]: nothing -> record {
    let blk = (try { (ast $src --json --minify).block | from json } catch { null })
    if $blk == null { return {} }
    let calls = ($blk.pipelines
        | each {|p| $p.elements | first | get expr.expr }
        | where {|e| ($e | describe) =~ '^record' and ('Call' in ($e | columns)) }
        | where {|c| ($c.Call.head.span_source? | default '') in ['def' 'export def'] })
    mut out = {}
    for c in $calls {
        let pos = ($c.Call.arguments | where {|a| 'Positional' in ($a | columns) } | each {|a| $a.Positional })
        let nm = ($pos | where {|p| 'String' in ($p.expr | columns) } | first | get expr.String)
        let sg = ($pos | where {|p| 'Signature' in ($p.expr | columns) } | first | get expr.Signature)
        $out = ($out | upsert $nm (sig-text $sg))
    }
    $out
}

# nushell's flattened tokens of a source, each its shape and its text.
export def tokens-of [src: string]: nothing -> table<shape: string, content: string> {
    let toks = (try { ast $src --flatten --json | from json } catch { null })
    if $toks == null or ($toks | is-empty) { return [] }
    $toks | each {|t| {shape: $t.shape, content: $t.content} }
}

# A source's calls through modules it imports: each module's name and its verb.
export def module-calls [src: string, names: list<string>]: nothing -> table<module: string, word: string> {
    let toks = (tokens-of $src)
    $toks | enumerate | each {|e|
        let words = ($e.item.content | split row ' ')
        if $e.item.shape == 'shape_external' and $e.item.content in $names {
            let arg = ($toks | get -o ($e.index + 1))
            let word = (if $arg != null and $arg.shape == 'shape_externalarg' { $arg.content } else { '' })
            {module: $e.item.content, word: $word}
        } else if $e.item.shape == 'shape_internalcall' and ($words | length) > 1 and ($words | first) in $names {
            {module: ($words | first), word: ($words | skip 1 | str join ' ')}
        }
    } | compact
}

# A body's calls: the internal commands and the calls through named modules.
export def call-count [src: string, names: list<string>]: nothing -> int {
    let toks = (tokens-of $src)
    let internal = ($toks | where shape == 'shape_internalcall' | length)
    let external = ($toks | where {|t| $t.shape == 'shape_external' and $t.content in $names } | length)
    $internal + $external
}
