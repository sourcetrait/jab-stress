const MATRIX = path self ../../../nuon/nuance/freshbuild/matrix.nuon
const MOVES = path self ../../../nuon/nuance/freshbuild/moves.nuon

# A tuple as the SDK keys a build: screaming snake, deduped, and sorted.
def tuple-of [symbols: list<string>]: nothing -> list<string> {
    $symbols | each {|s| $s | str screaming-snake-case } | uniq | sort
}

# The tree a tuple builds into, debug with DEBUG and release without.
def tree-of [tuple: list<string>]: nothing -> string {
    if 'DEBUG' in $tuple { 'debug' } else { 'release' }
}

# A tuple's text, its symbols joined by commas, `none` for none.
def tuple-text [tuple: list<string>]: nothing -> string {
    if ($tuple | is-empty) { 'none' } else { $tuple | str join ',' }
}

# The SHA-256 and the size of a file's bytes.
def digest-of [file: path]: nothing -> record<sha256: string, size: int> {
    let bytes = (open --raw $file | into binary)
    {sha256: ($bytes | hash sha256), size: ($bytes | bytes length)}
}

# The one target a fresh cache holds, the retire home `tmp` beside it aside.
def target-in [cache: path]: nothing -> string {
    let found = (glob ($cache | path join 'jab' 'target' '*')
        | where {|p| ($p | path type) == 'dir' and ($p | path basename) != 'tmp' })
    if ($found | length) != 1 { error make {msg: $"($cache) holds ($found | length) targets, not one"} }
    $found | first
}

# The workspace's programs, each its path from the checkout's root.
def programs-of [jab: path]: nothing -> list<string> {
    glob ($jab | path join '**' 'program.jab.toml')
    | where {|f| not ($f | path split | any {|part| $part in ['.git' '.target' 'target'] }) }
    | each {|f| $f | path dirname | path relative-to $jab }
    | sort
}

# A build at a tuple: the workspace's for `*`, the kernel's, or one program's.
def build-at [jab: path, cache: path, program: string, tuple: list<string>]: [
    nothing -> record<exit: int, stderr: string>
] {
    let tool = (if ($jab | path join 'nu' 'bin' 'do.nu' | path exists) { $jab | path join 'nu' 'bin' 'do.nu' } else { $jab | path join 'sdk' 'nu' 'jab.nu' })
    let at = (match $program {
        '*' => [$jab],
        'kernel' => [($jab | path join 'kernel') '--kernel'],
        _ => [$jab $program],
    })
    let set = (if ($tuple | is-empty) { [] } else { ['--set' ($tuple | str join ',')] })
    let r = (with-env {XDG_CACHE_HOME: $cache} { ^nu $tool build ...$at ...$set | complete })
    {exit: $r.exit_code, stderr: ($r.stderr | lines | last 8 | str join "\n")}
}

# A program's disk as a run builds it, `genromfs` over its assets, or null.
def disk-of [jab: path, target: path, program: string, tree: string]: nothing -> oneof<string, nothing> {
    let manifest = (open ($jab | path join $program 'program.jab.toml'))
    let declared = ($manifest | get -o assets | default '')
    let compiled = ($manifest | get -o target_assets | default '')
    if $declared == '' and $compiled == '' { return null }
    let dir = (if $compiled != '' {
        $target | path join 'asset' $program $compiled
    } else {
        $jab | path join $program $declared | path expand
    })
    if not ($dir | path exists) { error make {msg: $"($program): its assets name no directory at ($dir)"} }
    if ($manifest.name | str length) > 127 { error make {msg: $"($program): a volume name past 127 bytes"} }
    let image = ($target | path join $tree $program $"($manifest.name).romfs")
    let r = (^genromfs -d $dir -f $image -V $manifest.name | complete)
    if $r.exit_code != 0 { error make {msg: $"genromfs over ($dir): ($r.stderr)"} }
    $image
}

# A program's rows at a tuple: its image, its ELF, and its disk if it has one.
def program-rows [jab: path, target: path, program: string, tuple: list<string>]: [
    nothing -> table<program: string, profile: string, symbols: list<string>, role: string, path: string,
        sha256: string, size: int>
] {
    let tree = (tree-of $tuple)
    let name = (open ($jab | path join $program 'program.jab.toml') | get name)
    let dir = ($target | path join $tree $program)
    mut rows = []
    for r in [[role, file]; [program_jab, $"($name).jab"], [program_elf, $"($name).elf"]] {
        let f = ($dir | path join $r.file)
        if not ($f | path exists) { error make {msg: $"($program) at [(tuple-text $tuple)]: no ($r.file) in ($dir)"} }
        let d = (digest-of $f)
        $rows = ($rows | append {
            program: $program, profile: $tree, symbols: $tuple, role: $r.role,
            path: ([$program $r.file] | path join), sha256: $d.sha256, size: $d.size
        })
    }
    let disk = (disk-of $jab $target $program $tree)
    if $disk != null {
        let d = (digest-of $disk)
        $rows = ($rows | append {
            program: $program, profile: $tree, symbols: $tuple, role: 'romfs_disk',
            path: ([$program $"($name).romfs"] | path join), sha256: $d.sha256, size: $d.size
        })
    }
    $rows
}

# The kernel's rows at a tuple: its ELF and its loaded bytes, objcopy's image.
def kernel-rows [target: path, tuple: list<string>, scratch: path]: [
    nothing -> table<program: string, profile: string, symbols: list<string>, role: string, path: string,
        sha256: string, size: int>
] {
    let tree = (tree-of $tuple)
    let elf = ($target | path join $tree 'kernel' 'jab.elf')
    if not ($elf | path exists) { error make {msg: $"the kernel at [(tuple-text $tuple)]: no ($elf)"} }
    let flags = (open --raw ($elf | path dirname | path join 'flags') | decode | lines | first)
    let prefix = ($flags | split row ' ' | last)
    let bin = ($scratch | path join $"kernel_($tree)_(tuple-text $tuple | str replace --all ',' '_').bin")
    let r = (^$"($prefix)objcopy" -O binary $elf $bin | complete)
    if $r.exit_code != 0 { error make {msg: $"objcopy of ($elf): ($r.stderr)"} }
    let e = (digest-of $elf)
    let b = (digest-of $bin)
    [
        {program: 'kernel', profile: $tree, symbols: $tuple, role: 'kernel_elf', path: 'kernel/jab.elf',
            sha256: $e.sha256, size: $e.size}
        {program: 'kernel', profile: $tree, symbols: $tuple, role: 'kernel_loaded', path: 'kernel/jab.elf',
            sha256: $b.sha256, size: $b.size}
    ]
}

# A fresh build of the matrix from jab's HEAD, each artifact's digest in `out`.
export def manifest [jab: path, out: path]: nothing -> record<commit: string, builds: int, rows: int> {
    let jab = ($jab | path expand)
    let out = ($out | path expand)
    if ($out | path exists) { error make {msg: $"($out) exists; a manifest is taken into a new directory"} }
    let changed = (^git -C $jab status --porcelain | complete | get stdout | str trim)
    if $changed != '' { error make {msg: $"($jab) holds changes; a manifest is taken of a commit"} }
    let commit = (^git -C $jab rev-parse HEAD | complete | get stdout | str trim)
    let matrix: table<program: string, tuples: list<list<string>>> = (open $MATRIX)
    let cache = ($out | path join 'cache')
    let scratch = ($out | path join 'loaded')
    mkdir $cache
    mkdir $scratch
    let all = (programs-of $jab)
    mut rows = []
    mut builds = []
    mut kernels = {}
    for entry in $matrix {
        for t in $entry.tuples {
            let tuple = (tuple-of $t)
            let b = (build-at $jab $cache $entry.program $tuple)
            $builds = ($builds | append {program: $entry.program, symbols: $tuple, exit: $b.exit})
            if $b.exit != 0 { error make {msg: $"building ($entry.program) at [(tuple-text $tuple)]: ($b.stderr)"} }
            let target = (target-in $cache)
            let programs = (match $entry.program { '*' => $all, 'kernel' => [], _ => [$entry.program] })
            for p in $programs { $rows = ($rows | append (program-rows $jab $target $p $tuple)) }
            let k = (kernel-rows $target $tuple $scratch)
            let key = (tuple-text $tuple)
            let seen = ($kernels | get -o $key)
            if $seen == null {
                $kernels = ($kernels | insert $key ($k | get sha256))
                $rows = ($rows | append $k)
            } else if $seen != ($k | get sha256) {
                error make {msg: $"the kernel at [($key)] built twice to two digests"}
            }
        }
    }
    let keys = ($rows | each {|r| $"($r.program) ($r.profile) [(tuple-text $r.symbols)] ($r.role)" })
    let twice = ($keys | uniq --repeated)
    if ($twice | is-not-empty) { error make {msg: $"rows taken twice: ($twice | str join '; ')"} }
    let disks = ($rows | where role == 'romfs_disk' | group-by {|r| $"($r.program) ($r.profile)" })
    let unsteady = ($disks | transpose key rows | where {|g| ($g.rows | get sha256 | uniq | length) > 1 } | get key)
    if ($unsteady | is-not-empty) {
        error make {msg: $"disks of one tree built to two digests: ($unsteady | str join '; ')"}
    }
    {commit: $commit, builds: $builds, rows: $rows} | to nuon --indent 1 | save ($out | path join 'manifest.nuon')
    {commit: $commit, builds: ($builds | length), rows: ($rows | length)}
}

# A row's key: its program, its tree, its symbols, and its role.
def key-of [row: record]: nothing -> string {
    $"($row.program) ($row.profile) [(tuple-text $row.symbols)] ($row.role)"
}

# A program's path after the moves: under a moved path, at its new place.
def moved-program [moves: record, program: string]: nothing -> string {
    let m = ($moves.paths | where {|p| $program == $p.from or ($program | str starts-with $"($p.from)/") } | get -o 0)
    if $m == null { $program } else { $m.to + ($program | str substring ($m.from | str length)..) }
}

# A row after the moves: its program's new place and a renamed one's file name.
def moved-row [moves: record, row: record]: nothing -> record {
    if $row.program == 'kernel' { return $row }
    let program = (moved-program $moves $row.program)
    let renamed = ($moves.names | where program == $program | get -o 0)
    let parsed = ($row.path | path basename | path parse)
    let file = (if $renamed != null and $parsed.stem == $renamed.from {
        $parsed | update stem $renamed.to | path join
    } else { $row.path | path basename })
    $row | update program $program | update path ([$program $file] | path join)
}

# A renamed program's ELFs built under its old name in a worktree of the commit.
def remade-elves [jab: path, commit: string, names: table, rows: table, scratch: path]: [
    nothing -> table<key: string, sha256: string>
] {
    let wt = ($scratch | path join 'worktree')
    let cache = ($scratch | path join 'cache')
    let added = (^git -C $jab worktree add --detach $wt $commit | complete)
    if $added.exit_code != 0 { error make {msg: $"a worktree of ($commit): ($added.stderr)"} }
    let made = (try {
        let link = ($jab | path join 'extern' 'riscv')
        if ($link | path type) == 'symlink' {
            mkdir ($wt | path join 'extern')
            ^ln -s ($link | path expand) ($wt | path join 'extern' 'riscv')
        }
        for n in ($names | where {|n| $n.program in ($rows | get program) }) {
            let file = ($wt | path join $n.program 'program.jab.toml')
            let raw = (open --raw $file | decode)
            let named = ($raw | str replace $"name = '($n.to)'" $"name = '($n.from)'")
            if $named == $raw { error make {msg: $"($file) names no ($n.to)"} }
            $named | save -f $file
        }
        mkdir $cache
        mut elves = []
        for r in $rows {
            let b = (build-at $wt $cache $r.program $r.symbols)
            if $b.exit != 0 { error make {msg: $"remaking ($r.program) at [(tuple-text $r.symbols)]: ($b.stderr)"} }
            let old = ($names | where program == $r.program | get 0.from)
            let elf = (target-in $cache | path join $r.profile $r.program $"($old).elf")
            $elves = ($elves | append {key: (key-of $r), sha256: (digest-of $elf).sha256})
        }
        {elves: $elves, error: null}
    } catch {|e| {elves: [], error: $e.msg} })
    let removed = (^git -C $jab worktree remove --force $wt | complete)
    if $made.error != null { error make {msg: $made.error} }
    if $removed.exit_code != 0 { error make {msg: $"removing the worktree ($wt): ($removed.stderr)"} }
    $made.elves
}

# A renamed program's disk remade: its records' paths moved back, its old name.
def remade-disk [jab: path, target: path, row: record, place: string, old: string, scratch: path]: [
    nothing -> record<sha256: string, rewritten: list<string>>
] {
    let manifest = (open ($jab | path join $row.program 'program.jab.toml'))
    let compiled = ($manifest | get -o target_assets | default '')
    let dir = (if $compiled != '' {
        $target | path join 'asset' $row.program $compiled
    } else {
        $jab | path join $row.program ($manifest | get -o assets | default '') | path expand
    })
    let copy = ($scratch | path join $"tree_($row.profile)")
    cp -r $dir $copy
    let from = (($jab | path expand | path join $row.program) + (char path_sep))
    let to = (($jab | path expand | path join $place) + (char path_sep))
    let records = (glob ($copy | path join '**' '*.nuon') | where {|f| open --raw $f | decode | str contains $from })
    for f in $records { open --raw $f | decode | str replace --all $from $to | save -f $f }
    let image = ($scratch | path join $"($row.profile)_($old).romfs")
    let r = (^genromfs -d $copy -f $image -V $old | complete)
    if $r.exit_code != 0 { error make {msg: $"genromfs over ($copy): ($r.stderr)"} }
    {sha256: (digest-of $image).sha256, rewritten: ($records | each {|f| $f | path relative-to $copy })}
}

# A manifest after the moves held to one before, by role, differences named.
export def compare [before: path, after: path, jab: path]: [
    nothing -> record<ok: bool, rows: int, same: int, remade: int, refusals: int>
] {
    let moves = (open $MOVES)
    let b = (open ($before | path expand))
    let out = ($after | path expand)
    let a = (open ($out | path join 'manifest.nuon'))
    let target = (target-in ($out | path join 'cache'))
    let scratch = ($out | path join 'compared')
    if ($scratch | path exists) { error make {msg: $"($scratch) exists; a comparison is made once"} }
    mkdir $scratch
    let mapped = ($b.rows | each {|r| {before: $r, row: (moved-row $moves $r)} })
    let later = ($a.rows | reduce --fold {} {|r, acc| $acc | insert (key-of $r) $r })
    mut refusals = []
    mut same = 0
    mut owed = []
    for m in $mapped {
        let k = (key-of $m.row)
        let x = ($later | get -o $k)
        if $x == null {
            $refusals = ($refusals | append {kind: 'missing', key: $k, detail: 'no row after the moves'})
            continue
        }
        if $x.path != $m.row.path {
            let detail = $"($m.row.path) before the moves, ($x.path) after"
            $refusals = ($refusals | append {kind: 'path', key: $k, detail: $detail})
            continue
        }
        if $x.sha256 == $m.row.sha256 { $same += 1; continue }
        let renamed = ($moves.names | where program == $x.program | get -o 0)
        if $renamed != null and $x.role in ['program_elf' 'romfs_disk'] {
            $owed = ($owed | append {before: $m.before, after: $x, renamed: $renamed})
            continue
        }
        let detail = $"($m.row.sha256) before, ($x.sha256) after"
        $refusals = ($refusals | append {kind: 'differs', key: $k, detail: $detail})
    }
    let elves = ($owed | where {|o| $o.after.role == 'program_elf' } | get after)
    let remade = (if ($elves | is-empty) { [] } else { remade-elves $jab $a.commit $moves.names $elves $scratch })
    mut disks = {}
    mut proofs = []
    for o in $owed {
        let k = (key-of $o.after)
        let named = $"($o.renamed.from) before and ($o.renamed.to) after"
        let proof = (if $o.after.role == 'program_elf' {
            let sha = ($remade | where key == $k | get -o 0.sha256)
            {sha256: $sha, cause: $"its object named after the program, ($named)"}
        } else {
            let dk = $"($o.after.program) ($o.after.profile)"
            let d = (if ($disks | get -o $dk) != null { $disks | get $dk } else {
                remade-disk $jab $target $o.after $o.before.program $o.renamed.from $scratch
            })
            let records = ($d.rewritten | str join ', ')
            let cause = $"its volume named ($named); ($records) naming its sources at its place"
            {sha256: $d.sha256, cause: $cause, disk: $d}
        })
        if $o.after.role == 'romfs_disk' {
            $disks = ($disks | upsert $"($o.after.program) ($o.after.profile)" $proof.disk)
        }
        let held = ($proof.sha256 == $o.before.sha256)
        $proofs = ($proofs | append {
            key: $k, before: $o.before.sha256, after: $o.after.sha256, remade: $proof.sha256, held: $held,
            cause: $proof.cause
        })
        if not $held {
            let detail = $"remade under its old name and place to ($proof.sha256), where it was ($o.before.sha256)"
            $refusals = ($refusals | append {kind: 'remade', key: $k, detail: $detail})
        }
    }
    let earlier = ($mapped | each {|m| key-of $m.row })
    for x in $a.rows {
        let k = (key-of $x)
        if $k not-in $earlier {
            $refusals = ($refusals | append {kind: 'new', key: $k, detail: 'no row before the moves'})
        }
    }
    {
        before: {file: ($before | path expand), commit: $b.commit}, after: {file: $out, commit: $a.commit},
        moves: $moves, rows: ($mapped | length), same: $same, remade: $proofs, refusals: $refusals
    } | to nuon --indent 1 | save ($out | path join 'compare.nuon')
    {
        ok: ($refusals | is-empty), rows: ($mapped | length), same: $same, remade: ($proofs | length),
        refusals: ($refusals | length)
    }
}
