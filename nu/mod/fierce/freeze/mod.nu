use (path self ../../../../../jab/nu/mod/identity)
use (path self ../../../../../jab/nu/mod/supervise)

# The timing domain a launch under the supervisor measures in, as a freeze records it
const TIMING = "the supervisor's monotonic clock: the go's Instant, as the supervisor lets QEMU run, the origin of every receipt time, in nanoseconds; QEMU's CPU read by the supervisor every cpu_ns; a result's times in seconds from the go and its wall_seconds from the go to the reap; the caller's realtime clock gives dates alone. A run captured before this freeze keeps the timing it was captured under, its times from the caller's realtime start."

# The launcher a freeze's measurements run under: the supervisor's binary, its
# checkout, its bounds, and its timing domain
export def launcher-of [repo: string]: nothing -> record {
    let bin = (supervise binary)
    {
        supervisor: { path: $bin, sha256: (open --raw $bin | into binary | hash sha256) },
        built_from: (identity reader [$repo]).repos.0,
        bounds: (supervise bounds),
        timing: $TIMING,
    }
}

# A freeze's launcher written once to `out`, and the line naming it
export def launcher [repo: string, out: path]: nothing -> string {
    if ($out | path exists) { error make { msg: $"($out) exists; a freeze's launcher is recorded once" } }
    let l = (launcher-of $repo)
    $l | to nuon --indent 2 | save --raw $out
    $"launcher: ($l.supervisor.path), SHA-256 ($l.supervisor.sha256), built from ($l.built_from.commit)(if $l.built_from.dirty { ' with changes' } else { '' }); ($out)"
}

# The build symbols a set names: screaming snake case, each once, sorted
export def symbols-of [set: string]: nothing -> list<string> {
    $set | split row "," | each {|s| $s | str trim } | where {|s| $s != "" } | each {|s| $s | str screaming-snake-case } | uniq | sort
}

# An image's provenance, saved beside it as provenance.nuon and returned
export def provenance-of [repo: string, full: string, image: string, symbols: list<string>, build_tool: record]: nothing -> record {
    let beside = ($image | path dirname)
    let stem = ($image | path parse | get stem)
    let flags = (open --raw ($beside | path join "flags") | decode | lines | first)
    let prefix = ($flags | split row " " | last)
    let tool = {|name: string| let p = ($"($prefix)($name)" | path expand); { path: $p, sha256: (open --raw $p | into binary | hash sha256) } }
    let provenance = {
        commit: $full,
        symbols: $symbols,
        source: $"the program's src/ and manifest at ($full)",
        sdk: $"sdk/src at ($full), the export's own",
        build_tool: $build_tool,
        toolchain: {
            prefix: $prefix,
            version: (^$"($prefix)as" --version | complete | get stdout | lines | get -o 0),
            assembler: (do $tool "as"),
            linker: (do $tool "ld"),
            objcopy: (do $tool "objcopy"),
        },
        flags: $flags,
        image_sha256: (open --raw $image | into binary | hash sha256),
        elf_sha256: (open --raw ($beside | path join $"($stem).elf") | into binary | hash sha256),
    }
    let romfs = ($beside | path join $"($stem).romfs")
    let provenance = (if ($romfs | path exists) { $provenance | insert romfs_sha256 (open --raw $romfs | into binary | hash sha256) } else { $provenance })
    $provenance | to nuon --indent 2 | save --raw -f ($beside | path join "provenance.nuon")
    $provenance
}

# The game's place at a commit: kit/fierce, game/fps/1k, or game/fps
def game-place [repo: string, full: string]: nothing -> list<string> {
    let has = {|p: string| (^git -C $repo cat-file -e $"($full):($p)/program.jab.toml" | complete).exit_code == 0 }
    if (do $has "kit/fierce") { ["kit" "fierce"] } else if (do $has "game/fps/1k") { ["game" "fps" "1k"] } else { ["game" "fps"] }
}

# A commit's program exported and built release, or debug with `--debug`,
# gated, its provenance kept
export def main [repo: string, commit: string, cands: string, expected: string, --set: string = "", --program: string = "", --debug]: nothing -> nothing {
    let full = (^git -C $repo rev-parse $commit | complete | get stdout | str trim)
    if $full == "" { error make { msg: $"($commit) names no commit in ($repo)" } }
    let short = ($full | str substring 0..<7)
    let names = (symbols-of $set)
    let refused = ($names | where {|n| $n in [DEBUG RELEASE] })
    if not ($refused | is-empty) { error make { msg: $"an export's tree is its own: release with `release` its symbol, or debug by `--debug`; ($refused | str join ', ') cannot be among --set's" } }
    let place = (if $program == "" { game-place $repo $full } else { $program | split row "/" | where {|s| $s != "" } })
    let rel = ($place | str join "/")
    let shown = (^git -C $repo show $"($full):($rel)/program.jab.toml" | complete)
    if $shown.exit_code != 0 { error make { msg: $"($rel)/program.jab.toml is not in ($full): ($shown.stderr | str trim)" } }
    let original = ($shown.stdout | from toml)
    let declared = ($original | get -o assets | default "")
    let assets_rel = (if $declared == "" { null } else { $repo | path join $rel $declared | path expand | path relative-to ($repo | path expand) })
    if $assets_rel != null and ($original.name | str length) > 127 { error make { msg: $"($original.name) is past the 127 bytes a romfs volume's name holds" } }
    let label = (if $debug { "-debug" } else { "" }) + (if ($names | is-empty) { "" } else { "-" + ($names | str lowercase | str join "-") })
    let dir = ($cands | path join $"export_($short)($label)")
    if ($dir | path exists) { error make { msg: $"($dir) exists; an export is made once" } }
    mkdir $dir
    let tar = ($dir | path join "export.tar")
    let parts = (["sdk/src" $"($rel)/src" $"($rel)/program.jab.toml"] ++ (if $assets_rel == null { [] } else { [$assets_rel] }))
    let archived = (^git -C $repo archive --format=tar -o $tar $full ...$parts | complete)
    if $archived.exit_code != 0 { error make { msg: $"git archive of ($full): ($archived.stderr)" } }
    let unpacked = (^tar -xf $tar -C $dir | complete)
    if $unpacked.exit_code != 0 { error make { msg: $"tar -x of ($tar): ($unpacked.stderr)" } }
    let program_dir = ($dir | path join ...$place)
    let sdk = ($dir | path join "sdk")
    let paths = { name: $original.name, sdk: $sdk, workspace: $repo, includes: [($sdk | path join 'src')], link: ($sdk | path join 'src' 'program.ld') }
    let assets = (if $assets_rel == null { {} } else { { assets: ($dir | path join $assets_rel) } })
    let kept = ([specs reserved feature display paired] | reduce --fold {} {|k, acc| let v = ($original | get -o $k); if $v == null { $acc } else { $acc | insert $k $v } })
    $paths | merge $assets | merge $kept | to toml | save --raw -f ($program_dir | path join "program.jab.toml")
    let carried = (if $assets_rel == null { "sdk/src and the program's src/ and manifest" } else { $"sdk/src, the program's src/ and manifest, and its assets, ($assets_rel)," })
    let redirected = (if $assets_rel == null { "the manifest's sdk, includes, and link redirected into the export" } else { "the manifest's sdk, includes, link, and assets redirected into the export" })
    {
        commit: $full,
        symbols: $names,
        exported_from: $"git archive of ($carried) at ($full), ($redirected) and its workspace the checkout's for the kernel and the target, its declaration and run shape kept, (if ($kept | is-empty) { 'none' } else { $kept | columns | str join ', ' }), and its fields naming the program's own tree dropped",
    } | to nuon --indent 2 | save --raw ($program_dir | path join "source.nuon")
    let tree = (if $debug { "debug" } else { "release" })
    let build_tool = (identity reader [$repo] --launches)
    let built = (^($repo | path join "do") build $program_dir --set ([$tree] ++ ($names | str lowercase) | str join ",") | complete)
    if $built.exit_code != 0 { error make { msg: $"the ($tree) build of ($program_dir): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
    let image = (glob ($program_dir | path join "**" $"($original.name).jab") | get -o 0)
    if $image == null { error make { msg: $"no ($original.name).jab under ($program_dir)" } }
    if $assets_rel != null {
        let romfs = ($image | path dirname | path join $"($original.name).romfs")
        let made = (^genromfs -d ($dir | path join $assets_rel) -f $romfs -V $original.name | complete)
        if $made.exit_code != 0 { error make { msg: $"genromfs over ($assets_rel): ($made.stdout + $made.stderr | str trim)" } }
    }
    let flags = (open --raw ($image | path dirname | path join "flags") | decode | lines | first)
    if $debug != ($flags =~ '--defsym DEBUG=') { error make { msg: $"the ($tree) export built (if $debug { 'without' } else { 'with' }) DEBUG: ($flags)" } }
    let missing = ($names | where {|n| not ($flags | str contains $"--defsym ($n)=1") })
    if not ($missing | is-empty) { error make { msg: $"the export's flags lack ($missing | str join ', '): ($flags)" } }
    let provenance = (provenance-of $repo $full $image (if $debug { ["DEBUG"] ++ $names } else { $names }) $build_tool)
    if $expected != "" and $provenance.image_sha256 != $expected {
        error make { msg: $"the export's image has SHA-256 ($provenance.image_sha256) where ($expected) was expected" }
    }
    print $"export: ($image), SHA-256 ($provenance.image_sha256)(if $expected == '' { '' } else { ', as expected' })"
}
