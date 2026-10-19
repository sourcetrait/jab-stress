use (path self ../live)
use (path self ../imports)

# A refusal: what kind, where, the item, and why.
def refusal [kind: string, repo: string, file: string, line: int, item: string, detail: string]: [
    nothing -> record<kind: string, repo: string, file: string, line: int, item: string, detail: string>
] {
    {kind: $kind, repo: $repo, file: $file, line: $line, item: $item, detail: $detail}
}

# A path after the landed groups' moves, each a prefix moved whole.
export def mapped [contract: record, landed: list<string>, repo: string, file: string]: nothing -> string {
    mut f = $file
    for g in ($contract.groups | where {|g| $g.group in $landed }) {
        for m in ($g.moves | where repo == $repo) {
            if ($f | str starts-with $m.from) { $f = ($m.to + ($f | str substring ($m.from | str length)..)) }
        }
    }
    $f
}

# The families' monolith files where the landed groups have moved them.
def monolith-files [contract: record, landed: list<string>]: [
    nothing -> table<family: string, repo: string, file: string>
] {
    $contract.families | each {|f|
        $f.files | each {|x| {family: $f.family, repo: $f.repo, file: (mapped $contract $landed $f.repo $x)} }
    } | flatten
}

# A final name's def in its module: the name less the module's words, or main.
export def name-in-module [name: string, module: string]: nothing -> string {
    let parts = ($module | split row '/')
    mut words = ($name | split row ' ')
    mut i = 0
    while ($words | is-not-empty) and $i < ($parts | length) and ($words | first) == ($parts | get $i) {
        $words = ($words | skip 1)
        $i += 1
    }
    if ($words | is-empty) { 'main' } else { $words | str join ' ' }
}

# The file a family's module lives in.
def module-file [contract: record, family: string, module: string]: nothing -> oneof<string, nothing> {
    $contract.modules | where {|m| $m.family == $family and $m.module == $module } | get -o 0.file
}

# Whether a file lies inside a family, which may call its internal defs.
def inside [contract: record, family: string, file: string]: nothing -> bool {
    $contract.families | where family == $family | first | get inside | any {|p| $file =~ $p }
}

# A declaration's key: its checkout, file, kind, and name.
def key-of [repo: string, file: string, kind: string, name: string]: nothing -> string {
    [$repo $file $kind $name] | str join '|'
}

# The live declarations, keyed by checkout, file, kind, and name.
def keyed [decls: table]: nothing -> record {
    $decls | reduce --fold {} {|d, acc| $acc | upsert (key-of $d.repo $d.file $d.kind $d.name) $d.line }
}

# A file's signature for a def, or null.
def sig-at [sigs: record, repo: string, file: string, def: string]: nothing -> oneof<string, nothing> {
    $sigs | get -o ([$repo $file] | str join '|') | default {} | get -o $def
}

# Each monolith def in its old place or its new, never both, never the old once
# its group landed, its signature the contract's.
export def places [contract: record, landed: list<string>, decls: table, sigs: record]: nothing -> table {
    let live = (keyed $decls)
    mut out = []
    for d in $contract.defs {
        let old = (if $d.file == null { null } else { mapped $contract $landed $d.repo $d.file })
        let new_file = (if $d.module == null { null } else { module-file $contract $d.family $d.module })
        let new_def = (if $d.module == null { null } else { name-in-module $d.name $d.module })
        let at_old = ($old != null and ($live | get -o (key-of $d.repo $old def $d.def)) != null)
        let at_new = ($new_file != null and ($live | get -o (key-of $d.repo $new_file def $new_def)) != null)
        let due = ($d.group in $landed)
        let item = $"($d.def) \(($d.family)\)"
        let where_ = ($old | default $new_file)
        if $d.fate == 'moves' {
            if (not $at_old) and (not $at_new) and ($d.file != null or $due) {
                let why = $"in neither ($old | default 'its old place') nor ($new_file) as ($new_def)"
                $out = ($out | append (refusal missing $d.repo $where_ 0 $item $why))
            }
            if $at_old and $at_new {
                $out = ($out | append (refusal twice $d.repo $old 0 $item $"in ($old) and ($new_file) at once"))
            }
            if $at_old and $due {
                $out = ($out | append (refusal stale $d.repo $old 0 $item $"in its old place after ($d.group) landed"))
            }
        } else if $d.fate == 'retired' {
            if $at_old and $due {
                $out = ($out | append (refusal stale $d.repo $old 0 $item $"($d.detail), yet here after ($d.group)"))
            }
        } else if not $at_old {
            $out = ($out | append (refusal missing $d.repo $old 0 $item $"($d.detail), absent from ($old)"))
        }
        if $at_old and $d.old_signature != null {
            let s = (sig-at $sigs $d.repo $old $d.def)
            if $s != $d.old_signature {
                let why = $"($s), the contract's ($d.old_signature)"
                $out = ($out | append (refusal signature $d.repo $old 0 $item $why))
            }
        }
        if $at_new and $d.signature != null {
            let s = (sig-at $sigs $d.repo $new_file $new_def)
            if $s != $d.signature {
                let why = $"($s), the contract's ($d.signature)"
                $out = ($out | append (refusal signature $d.repo $new_file 0 $item $why))
            }
        }
    }
    $out
}

# Each constant of the monoliths in its old place or under its family's modules.
export def constants [contract: record, landed: list<string>, decls: table]: nothing -> table {
    let live = (keyed $decls)
    let consts = ($decls | where kind == 'const')
    mut out = []
    for k in $contract.consts {
        let old = (mapped $contract $landed $k.repo $k.file)
        let at_old = (($live | get -o (key-of $k.repo $old const $k.const)) != null)
        let home = (if $k.family == 'sdk' { 'nu/mod/' } else { 'kit/fierce/nu/mod/' })
        let at_new = (if $k.module != null {
            let file = (module-file $contract $k.family $k.module)
            ($live | get -o (key-of $k.repo $file const $k.const)) != null
        } else {
            $consts | any {|c| $c.repo == $k.repo and $c.name == $k.const and ($c.file | str starts-with $home) }
        })
        if (not $at_old) and (not $at_new) {
            $out = ($out | append (refusal missing $k.repo $old 0 $k.const $"in neither ($old) nor under ($home)"))
        }
        if $at_old and ($k.group in $landed) {
            $out = ($out | append (refusal stale $k.repo $old 0 $k.const $"in its old place after ($k.group) landed"))
        }
    }
    $out
}

# Each owned file's declarations in place or at its home, the retired ones gone.
export def files [contract: record, landed: list<string>, decls: table]: nothing -> table {
    mut out = []
    for f in $contract.files {
        let old = (mapped $contract $landed $f.repo $f.file)
        let moved = ($f.home != null and $f.group != null and $f.group in $landed)
        let here = ($decls | where {|d| $d.repo == $f.repo and $d.file == $old })
        let homed = (if $moved {
            $decls | where {|x| $x.repo == $f.repo and ($x.file | str starts-with $f.home) }
        } else { [] })
        for d in $f.declarations {
            let at_old = ($here | any {|x| $x.kind == $d.kind and $x.name == $d.name })
            let retired = ($d | get -o retired)
            if $retired != null and $retired in $landed {
                if $at_old {
                    let why = $"($d.kind) retired by ($retired), yet here"
                    $out = ($out | append (refusal stale $f.repo $old 0 $d.name $why))
                }
                continue
            }
            if $moved {
                let at_home = ($homed | any {|x| $x.kind == $d.kind and $x.name == $d.name })
                if $at_old {
                    let why = $"in its old file after ($f.group) landed"
                    $out = ($out | append (refusal stale $f.repo $old 0 $d.name $why))
                }
                if not $at_home {
                    let why = $"($d.kind) of ($f.file), not under it"
                    $out = ($out | append (refusal missing $f.repo $f.home 0 $d.name $why))
                }
            } else if not $at_old {
                $out = ($out | append (refusal missing $f.repo $old 0 $d.name $"($d.kind) the contract places here"))
            }
        }
    }
    $out
}

# The keys of every declaration the contract places by name.
def placed-keys [contract: record, landed: list<string>]: nothing -> record {
    let monolith = ($contract.defs | where file != null | each {|d|
        key-of $d.repo (mapped $contract $landed $d.repo $d.file) def $d.def
    })
    let consts = ($contract.consts | each {|k|
        key-of $k.repo (mapped $contract $landed $k.repo $k.file) const $k.const
    })
    let moved = ($contract.defs | where module != null | each {|d|
        key-of $d.repo (module-file $contract $d.family $d.module) def (name-in-module $d.name $d.module)
    })
    let cases = ($contract.cases | where part != 'suite' | each {|c|
        key-of jab (module-file $contract fierce $c.part) def $c.def
    })
    let o = $contract.orchestrator
    let orchestrated = ([main] | append ($contract.cases | where part == 'suite' | get def) | each {|n|
        key-of $o.repo $o.file def $n
    })
    $monolith | append $consts | append $moved | append $cases | append $orchestrated
    | reduce --fold {} {|k, acc| $acc | upsert $k true }
}

# Every live declaration the contract owns; one it does not refused at its line.
export def ownership [contract: record, landed: list<string>, decls: table]: nothing -> table {
    let placed = (placed-keys $contract $landed)
    let owned = ($contract.files | each {|f| $f | insert at (mapped $contract $landed $f.repo $f.file) })
    mut out = []
    for d in $decls {
        if ($placed | get -o (key-of $d.repo $d.file $d.kind $d.name)) != null { continue }
        let bin = ($contract.bin_dirs | any {|b| $b.repo == $d.repo and ($d.file | str starts-with $b.dir) })
        let verb = ($d.kind == 'def' and (($d.name == 'main') or ($d.name | str starts-with 'main ')))
        if $bin and $verb { continue }
        let module = ($contract.modules | where {|m| $m.repo == $d.repo and $m.file == $d.file } | get -o 0)
        if $module != null and $d.kind == 'const' {
            let ours = ($contract.consts | any {|k|
                let placed_here = ($k.module == null or $k.module == $module.module)
                $k.family == $module.family and $k.const == $d.name and $placed_here
            })
            if $ours { continue }
        }
        let owners = ($owned | where {|f|
            let homed = ($f.home != null and $f.group in $landed and ($d.file | str starts-with $f.home))
            $f.repo == $d.repo and ($f.at == $d.file or $homed)
        })
        if ($owners | any {|f| $f.declarations | any {|x| $x.kind == $d.kind and $x.name == $d.name } }) { continue }
        let why = $"a ($d.kind) the contract does not own"
        $out = ($out | append (refusal unowned $d.repo $d.file $d.line $d.name $why))
    }
    $out
}

# The module a file of the contract holds, by its file or a leaf's old file
# where the landed groups have moved it.
def module-at [contract: record, landed: list<string>, key: string]: nothing -> oneof<record, nothing> {
    let m = ($contract.modules | where {|m| (key-of $m.repo $m.file '' '') == $key } | get -o 0)
    if $m != null { return $m }
    $contract.modules | where {|m|
        $m.old_file != null and (key-of $m.repo (mapped $contract $landed $m.repo $m.old_file) '' '') == $key
    } | get -o 0
}

# Every import resolved, every module edge the contract's, and no cycle.
export def import-rules [contract: record, landed: list<string>, roots: record, sources: table]: [
    nothing -> record<refusals: table, edges: int>
] {
    let allowed = ($contract.edges
        | reduce --fold {} {|e, acc| $acc | upsert ([$e.family $e.from $e.to] | str join '|') true })
    let placed = (monolith-files $contract $landed)
    let monoliths = ($placed | each {|x| key-of $x.repo $x.file '' '' })
    mut out = []
    mut edges = []
    for s in $sources {
        let from = (key-of $s.repo $s.file '' '')
        let m = (module-at $contract $landed $from)
        let is_module = ($m != null and ($contract.modules | any {|x| (key-of $x.repo $x.file '' '') == $from }))
        for imp in (imports lines-of $s.src) {
            let r = (imports resolve $roots $s.repo $s.file $s.kind $s.src $imp $placed)
            if $r.kind == 'refused' {
                $out = ($out | append (refusal import $s.repo $s.file $imp.line $imp.target $r.detail))
                continue
            }
            if $r.kind != 'file' { continue }
            let to = (key-of $r.repo $r.file '' '')
            if $s.kind == 'nu' { $edges = ($edges | append {from: $from, to: $to}) }
            if (not $is_module) or ($to in $monoliths) { continue }
            let target = (module-at $contract $landed $to)
            if $target == null {
                let why = $"($m.module) imports no module's file"
                $out = ($out | append (refusal edge $s.repo $s.file $imp.line $r.file $why))
                continue
            }
            let name = (if $target.family == $m.family { $target.module } else { $"($target.family)/($target.module)" })
            if ($allowed | get -o ([$m.family $m.module $name] | str join '|')) == null {
                let why = $"($m.module) to ($name), outside the edges"
                $out = ($out | append (refusal edge $s.repo $s.file $imp.line $r.file $why))
            }
        }
    }
    for c in (imports cycles-of $edges) {
        let p = ($c | split row '|')
        $out = ($out | append (refusal cycle ($p | get 0) ($p | get 1) 0 ($p | get 1) 'on a cycle of imports'))
    }
    {refusals: $out, edges: ($edges | length)}
}

# The name nushell gives an import: a file's stem, or a module directory's name.
def import-name [file: string]: nothing -> string {
    if ($file | path basename) == 'mod.nu' {
        $file | path dirname | path basename
    } else {
        $file | path parse | get stem
    }
}

# The contract's def a call reaches, through an old monolith or a module.
def def-of [contract: record, landed: list<string>, family: string, target: string, word: string]: [
    nothing -> oneof<record, nothing>
] {
    let files = (monolith-files $contract $landed | where family == $family | get file)
    if $target in $files {
        let found = ($contract.defs | where {|d|
            $d.family == $family and $d.file != null and (mapped $contract $landed $d.repo $d.file) == $target and $d.def == $word
        })
        return ($found | get -o 0)
    }
    let m = ($contract.modules | where {|x| $x.family == $family and $x.file == $target } | get -o 0)
    if $m == null { return null }
    let own = ($contract.defs
        | where {|d| $d.family == $family and $d.module == $m.module and (name-in-module $d.name $d.module) == $word }
        | get -o 0)
    if $own != null { return $own }
    let under = $"($m.module)/"
    $contract.defs
    | where {|d| $d.family == $family and $d.module != null and ($d.module | str starts-with $under) }
    | where {|d| (name-in-module $d.name $m.module) == $word }
    | get -o 0
}

# The family files a source imports from outside them: each its name and list.
def reached [contract: record, landed: list<string>, roots: record, s: record]: nothing -> table {
    let monoliths = (monolith-files $contract $landed)
    let modules = ($contract.modules | each {|m| {family: $m.family, repo: $m.repo, file: $m.file} })
    let family_files = ($monoliths | append $modules)
    imports lines-of $s.src | each {|imp|
        let r = (imports resolve $roots $s.repo $s.file $s.kind $s.src $imp $family_files)
        if $r.kind == 'file' {
            let fam = ($family_files | where {|x| $x.repo == $r.repo and $x.file == $r.file } | get -o 0)
            if $fam != null and not (inside $contract $fam.family $s.file) {
                {family: $fam.family, file: $r.file, name: (import-name $r.file), list: $imp.list, line: $imp.line}
            }
        }
    } | compact
}

# No consumer outside a family calls one of its internal or private defs.
export def consumer-rules [contract: record, landed: list<string>, roots: record, sources: table]: [
    nothing -> record<refusals: table, calls: int>
] {
    mut out = []
    mut calls = 0
    let monoliths = (monolith-files $contract $landed)
    for s in $sources {
        let reach = (reached $contract $landed $roots $s)
        if ($reach | is-empty) { continue }
        let words = (live module-calls $s.src ($reach | get name))
        for r in $reach {
            let named = ($words | where module == $r.name | get word | append $r.list
                | where {|w| $w not-in ['' '*'] }
                | uniq)
            let through = ($monoliths | any {|x| $x.family == $r.family and $x.file == $r.file })
            for w in $named {
                $calls += 1
                let d = (def-of $contract $landed $r.family $r.file $w)
                if $d != null and $d.class in ['internal' 'private'] {
                    let why = $"a consumer calling ($r.family)'s ($d.class) ($d.def)"
                    $out = ($out | append (refusal consumer $s.repo $s.file $r.line $"($r.name) ($w)" $why))
                }
                if $d != null and $through and $d.fate == 'moves' and $d.group in $landed {
                    let why = $"a consumer calling ($d.def) through ($r.file) after ($d.group) moved it to ($d.module)"
                    $out = ($out | append (refusal moved $s.repo $s.file $r.line $"($r.name) ($w)" $why))
                }
            }
        }
    }
    {refusals: $out, calls: $calls}
}

# Each bin's verb one call of one module function.
export def bin-rules [contract: record, sources: table, decls: table]: nothing -> table {
    mut out = []
    for s in ($sources | where kind == 'nu') {
        if not ($contract.bin_dirs | any {|b| $b.repo == $s.repo and ($s.file | str starts-with $b.dir) }) { continue }
        let names = (imports lines-of $s.src | each {|i| import-name $i.target })
        let lines = ($s.src | lines)
        let here = ($decls | where {|d| $d.repo == $s.repo and $d.file == $s.file } | sort-by line)
        for e in ($here | enumerate) {
            if $e.item.kind != 'def' { continue }
            let next = ($here | get -o ($e.index + 1))
            let last = (if $next != null { $next.line - 1 } else { $lines | length })
            let text = ($lines | slice ($e.item.line - 1)..<$last | str join "\n")
            let n = ((live call-count $text $names) - 1)
            if $n > 1 {
                $out = ($out | append (refusal bin $s.repo $s.file $e.item.line $e.item.name $"($n) calls, a verb one"))
            }
        }
    }
    $out
}

# Once FierceModules lands: each case in its part with the contract's signature,
# the orchestrator calling each once in the table's order.
export def case-rules [
    contract: record, landed: list<string>, sources: table, decls: table, sigs: record
]: nothing -> table {
    if 'FierceModules' not-in $landed { return [] }
    let live = (keyed $decls)
    let parted = ($contract.cases | where part != 'suite' | sort-by order)
    mut out = []
    for c in $parted {
        let file = (module-file $contract fierce $c.part)
        if ($live | get -o (key-of jab $file def $c.def)) == null {
            $out = ($out | append (refusal case jab $file 0 $c.case $"no def ($c.def) in ($c.part)"))
            continue
        }
        let s = (sig-at $sigs jab $file $c.def)
        if $s != $c.signature {
            $out = ($out | append (refusal case jab $file 0 $c.case $"($s), the contract's ($c.signature)"))
        }
    }
    let o = $contract.orchestrator
    let src = ($sources | where {|s| $s.repo == $o.repo and $s.file == $o.file } | get -o 0.src)
    if $src == null { return ($out | append (refusal case $o.repo $o.file 0 $o.def 'no orchestrator')) }
    let parts = ($parted | get part | uniq | each {|p| $p | path basename })
    let made = (live module-calls $src $parts | each {|c| $"($c.module) ($c.word)" })
    let wanted = ($parted | each {|c| $"($c.part | path basename) ($c.def)" })
    if $made != $wanted {
        let why = $"($made | length) case calls where the table orders ($wanted | length), or in another order"
        $out = ($out | append (refusal case $o.repo $o.file 0 'orchestration' $why))
    }
    $out
}

# The planned transformations made once their groups have landed.
export def transformation-rules [contract: record, landed: list<string>, decls: table]: nothing -> table {
    let live = (keyed $decls)
    mut out = []
    for t in ($contract.transformations | where {|t| $t.group in $landed }) {
        let checks = (match $t.kind {
            'merge' => [{module: build, def: clean}],
            'rename' => [{module: probe, def: 'probe-kind'}],
            'helpers' => [{module: word, def: le} {module: word, def: zeros}],
            _ => []
        })
        for k in $checks {
            let file = (module-file $contract $t.family $k.module)
            if ($live | get -o (key-of jab $file def $k.def)) == null {
                let why = $"($t.kind) of ($t.old) not made: no ($k.def) in ($k.module)"
                $out = ($out | append (refusal transformation jab $file 0 $t.new $why))
            }
        }
    }
    $out
}
