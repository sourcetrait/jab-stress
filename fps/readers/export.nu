# ImageProvenance (FrameCeiling.md, TwoWorkers' audit): a measured image
# frozen with its provenance. `git archive` of a commit's `sdk/src` and
# the program's `src/` and manifest, at the commit's own place for it,
# `game/fps/1k` before FpsRootLayout and `game/fps` after, into
# `<cands>/export_<commit>`, the
# manifest's `sdk`, `includes`, and `link` redirected into the export,
# since the builder reads `link` itself, and its `workspace` the
# checkout's, whose kernel and target the runs use; its declaration,
# `specs`, `[reserved]`, and `[feature]`, kept, so the image reserves
# what the program declares, and `prepare`, `do`, and `target_assets`,
# which name the program's own tree, dropped; `source.nuon` naming
# the commit; built release there by the checkout's `sdk/nu/jab.nu`
# through a scratch justfile's `cand-build-release`; then beside the image,
# which the build writes with its `home`, `flags`, and `fps.elf`,
# `provenance.nuon`: the commit for the source and the SDK, the build
# tool's revision apart (the checkout's commit, its dirty state, and
# `sdk/nu/jab.nu`'s SHA-256), the toolchain's prefix, its advertised
# version, and the SHA-256 of the resolved assembler, linker, and objcopy,
# the image's and the ELF's SHA-256. A gate before anything measures it:
# the image's SHA-256 the one `expected` names, unless `expected` is "".
# Run under the real nu from a scratch justfile: `nu export.nu <repo>
# <commit> <cands> <jf> <expected>`.

def main [repo: string, commit: string, cands: string, jf: string, expected: string] {
    let full = (^git -C $repo rev-parse $commit | complete | get stdout | str trim)
    if $full == "" { error make { msg: $"($commit) names no commit in ($repo)" } }
    let short = ($full | str substring 0..<7)
    let dir = ($cands | path join $"export_($short)")
    if ($dir | path exists) { error make { msg: $"($dir) exists; an export is made once" } }
    mkdir $dir
    let tar = ($dir | path join "export.tar")
    let tiered = ((^git -C $repo cat-file -e $"($full):game/fps/1k/program.jab.toml" | complete).exit_code == 0)
    let place = (if $tiered { ["game" "fps" "1k"] } else { ["game" "fps"] })
    let rel = ($place | str join "/")
    let archived = (^git -C $repo archive --format=tar -o $tar $full sdk/src $"($rel)/src" $"($rel)/program.jab.toml" | complete)
    if $archived.exit_code != 0 { error make { msg: $"git archive of ($full): ($archived.stderr)" } }
    let unpacked = (^tar -xf $tar -C $dir | complete)
    if $unpacked.exit_code != 0 { error make { msg: $"tar -x of ($tar): ($unpacked.stderr)" } }
    let program = ($dir | path join ...$place)
    let sdk = ($dir | path join "sdk")
    let original = (open ($program | path join "program.jab.toml"))
    let paths = { name: $original.name, sdk: $sdk, workspace: $repo, includes: [($sdk | path join 'src')], link: ($sdk | path join 'src' 'program.ld') }
    let declaration = ([specs reserved feature] | reduce --fold {} {|k, acc| let v = ($original | get -o $k); if $v == null { $acc } else { $acc | insert $k $v } })
    $paths | merge $declaration | to toml | save --raw -f ($program | path join "program.jab.toml")
    {
        commit: $full,
        exported_from: $"git archive of sdk/src and the program's src/ and manifest at ($full), the manifest's sdk, includes, and link redirected into the export and its workspace the checkout's for the kernel and the target, its declaration kept, (if ($declaration | is-empty) { 'none' } else { $declaration | columns | str join ', ' }), and its fields naming the program's own tree dropped",
    } | to nuon --indent 2 | save --raw ($program | path join "source.nuon")
    let built = (^just -f $jf cand-build-release $program | complete)
    if $built.exit_code != 0 { error make { msg: $"the release build of ($program): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
    let image = (glob ($program | path join "**" "fps.jab") | get -o 0)
    if $image == null { error make { msg: $"no fps.jab under ($program)" } }
    let beside = ($image | path dirname)
    let flags = (open --raw ($beside | path join "flags") | decode | lines | first)
    if ($flags =~ '--defsym DEBUG=') { error make { msg: $"the export built with DEBUG: ($flags)" } }
    let prefix = ($flags | split row " " | last)
    let tool = {|name: string| let p = ($"($prefix)($name)" | path expand); { path: $p, sha256: (open --raw $p | into binary | hash sha256) } }
    let image_sha = (open --raw $image | into binary | hash sha256)
    let checkout = (^git -C $repo rev-parse HEAD | complete | get stdout | str trim)
    let dirty = ((^git -C $repo status --porcelain | complete | get stdout | str trim) != "")
    let provenance = {
        commit: $full,
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
        image_sha256: $image_sha,
        elf_sha256: (open --raw ($beside | path join "fps.elf") | into binary | hash sha256),
    }
    $provenance | to nuon --indent 2 | save --raw -f ($beside | path join "provenance.nuon")
    if $expected != "" and $image_sha != $expected {
        error make { msg: $"the export's image has SHA-256 ($image_sha) where ($expected) was expected" }
    }
    print $"export: ($image), SHA-256 ($image_sha)(if $expected == '' { '' } else { ', as expected' })"
}
