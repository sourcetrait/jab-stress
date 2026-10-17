# ImageProvenance (FrameCeiling.md, TwoWorkers' audit): a measured image
# frozen with its provenance. `git archive` of a commit's `sdk/src`, the
# program's `src/` and manifest, and the directory its manifest's
# `assets` names, the program `--program`'s (game/fps unless given, at
# the commit's own place for it, `game/fps/1k` before FpsRootLayout and
# `game/fps` after; walk's CADENCE images `example/walk`), into
# `<cands>/export_<commit>`, each symbol of `--set` added to the name after
# a dash (`export_<commit>-footprint`), the
# manifest's `sdk`, `includes`, and `link` redirected into the export,
# since the builder reads `link` itself, its `assets` to the export's
# copy, and its `workspace` the checkout's, whose kernel and target the
# runs use; its declaration, `specs`, `[reserved]`, and `[feature]`, and
# the run's shape, `display` and `paired`, kept, so the image reserves
# what the program declares, and `prepare`, `do`, and `target_assets`,
# which name the program's own tree, dropped; `source.nuon` naming
# the commit and the symbols; built release there by the checkout's
# `sdk/nu/jab.nu` through a scratch justfile's `cand-build-release`, which
# takes the symbols as its set beside `release`; a program with assets
# given its romfs beside the image, `<name>.romfs`, genromfs over the
# export's copy with the program's name as the volume, as the tool's run
# makes it; then beside the image, which the build writes with its `home`,
# `flags`, and `<name>.elf`, `provenance.nuon` (provenance-of). A gate
# before anything measures it: the image's SHA-256 the one `expected`
# names, unless `expected` is "". DEBUG and RELEASE are refused among the
# symbols, a measured image being a release build and `release` the
# build's own. Run under the real nu from a scratch justfile: `nu
# export.nu <repo> <commit> <cands> <jf> <expected> [--set <symbols>]
# [--program <path>]`, the symbols comma separated.

# The build symbols a set names as the tool makes them: screaming snake
# case, each once, sorted.
export def symbols-of [set: string]: nothing -> list<string> {
    $set | split row "," | each {|s| $s | str trim } | where {|s| $s != "" } | each {|s| $s | str screaming-snake-case } | uniq | sort
}

# An image's provenance, written beside it as `provenance.nuon` and
# returned: the commit for the source and the SDK, the symbols the build
# names beside its tree's, the build tool's revision apart (the checkout's
# commit, its dirty state, and `sdk/nu/jab.nu`'s SHA-256), the
# toolchain's prefix, its advertised version, and the SHA-256 of the
# resolved assembler, linker, and objcopy, the flags, and the image's and
# the ELF's SHA-256, the ELF the image's stem's; and the romfs's, the
# stem's too, when one sits beside the image.
export def provenance-of [repo: string, full: string, image: string, symbols: list<string>]: nothing -> record {
    let beside = ($image | path dirname)
    let stem = ($image | path parse | get stem)
    let flags = (open --raw ($beside | path join "flags") | decode | lines | first)
    let prefix = ($flags | split row " " | last)
    let tool = {|name: string| let p = ($"($prefix)($name)" | path expand); { path: $p, sha256: (open --raw $p | into binary | hash sha256) } }
    let checkout = (^git -C $repo rev-parse HEAD | complete | get stdout | str trim)
    let dirty = ((^git -C $repo status --porcelain | complete | get stdout | str trim) != "")
    let provenance = {
        commit: $full,
        symbols: $symbols,
        source: $"the program's src/ and manifest at ($full)",
        sdk: $"sdk/src at ($full), the export's own",
        build_tool: { checkout: $checkout, dirty: $dirty, jab_nu_sha256: (open --raw ($repo | path join "sdk" "nu" "jab.nu") | into binary | hash sha256) },
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

def main [repo: string, commit: string, cands: string, jf: string, expected: string, --set: string = "", --program: string = "game/fps"] {
    let full = (^git -C $repo rev-parse $commit | complete | get stdout | str trim)
    if $full == "" { error make { msg: $"($commit) names no commit in ($repo)" } }
    let short = ($full | str substring 0..<7)
    let names = (symbols-of $set)
    let refused = ($names | where {|n| $n in [DEBUG RELEASE] })
    if not ($refused | is-empty) { error make { msg: $"an export is a release build with `release` its own symbol; ($refused | str join ', ') cannot be among --set's" } }
    let place = (if $program == "game/fps" {
        let tiered = ((^git -C $repo cat-file -e $"($full):game/fps/1k/program.jab.toml" | complete).exit_code == 0)
        if $tiered { ["game" "fps" "1k"] } else { ["game" "fps"] }
    } else { $program | split row "/" | where {|s| $s != "" } })
    let rel = ($place | str join "/")
    let shown = (^git -C $repo show $"($full):($rel)/program.jab.toml" | complete)
    if $shown.exit_code != 0 { error make { msg: $"($rel)/program.jab.toml is not in ($full): ($shown.stderr | str trim)" } }
    let original = ($shown.stdout | from toml)
    let declared = ($original | get -o assets | default "")
    let assets_rel = (if $declared == "" { null } else { $repo | path join $rel $declared | path expand | path relative-to ($repo | path expand) })
    if $assets_rel != null and ($original.name | str length) > 127 { error make { msg: $"($original.name) is past the 127 bytes a romfs volume's name holds" } }
    let label = (if ($names | is-empty) { "" } else { "-" + ($names | str lowercase | str join "-") })
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
    let built = (if ($names | is-empty) { ^just -f $jf cand-build-release $program_dir | complete } else { ^just -f $jf cand-build-release $program_dir ($names | str lowercase | str join ",") | complete })
    if $built.exit_code != 0 { error make { msg: $"the release build of ($program_dir): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
    let image = (glob ($program_dir | path join "**" $"($original.name).jab") | get -o 0)
    if $image == null { error make { msg: $"no ($original.name).jab under ($program_dir)" } }
    if $assets_rel != null {
        let romfs = ($image | path dirname | path join $"($original.name).romfs")
        let made = (^genromfs -d ($dir | path join $assets_rel) -f $romfs -V $original.name | complete)
        if $made.exit_code != 0 { error make { msg: $"genromfs over ($assets_rel): ($made.stdout + $made.stderr | str trim)" } }
    }
    let flags = (open --raw ($image | path dirname | path join "flags") | decode | lines | first)
    if ($flags =~ '--defsym DEBUG=') { error make { msg: $"the export built with DEBUG: ($flags)" } }
    let missing = ($names | where {|n| not ($flags | str contains $"--defsym ($n)=1") })
    if not ($missing | is-empty) { error make { msg: $"the export's flags lack ($missing | str join ', '): ($flags)" } }
    let provenance = (provenance-of $repo $full $image $names)
    if $expected != "" and $provenance.image_sha256 != $expected {
        error make { msg: $"the export's image has SHA-256 ($provenance.image_sha256) where ($expected) was expected" }
    }
    print $"export: ($image), SHA-256 ($provenance.image_sha256)(if $expected == '' { '' } else { ', as expected' })"
}
