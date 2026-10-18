const MATRIX = path self ../../../nuon/nuance/freshbuild/matrix.nuon

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
    let tool = ($jab | path join 'sdk' 'nu' 'jab.nu')
    let at = (match $program {
        '*' => [$jab],
        'kernel' => [($jab | path join 'kernel') '--kernel'],
        _ => [$jab $program],
    })
    let set = (if ($tuple | is-empty) { [] } else { ['--set' ($tuple | str join ',')] })
    let r = (with-env {XDG_CACHE_HOME: $cache} { ^nu $tool build ...$at ...$set | complete })
    {exit: $r.exit_code, stderr: ($r.stderr | lines | last 8 | str join "\n")}
}

# A program's disk built as a run builds it, `genromfs` over its assets, or null.
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
    if ($unsteady | is-not-empty) { error make {msg: $"disks of one tree built to two digests: ($unsteady | str join '; ')"} }
    {commit: $commit, builds: $builds, rows: $rows} | to nuon --indent 1 | save ($out | path join 'manifest.nuon')
    {commit: $commit, builds: ($builds | length), rows: ($rows | length)}
}
