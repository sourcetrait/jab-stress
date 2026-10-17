# A kernel candidate's export (SubmitWait, and JointTiming's P0 and P2): a
# measured kernel frozen with its provenance. `git archive` of a commit's
# `kernel/src`, `kernel/kernel.jab.toml`, and `sdk/src` into
# `<cands>/kexport_<commit>[-<symbol>...]`; the manifest's `workspace`
# the checkout's, so the toolchain is the checkout's `extern/riscv` and the
# code's layout the suite's, and its `do`, a script the export does not
# carry, dropped; `source.nuon` naming the commit and the symbols; built
# release with the symbols by the checkout's `sdk/nu/jab.nu`, the export
# lying in the checkout's target, so the build lands beside it in
# `kernel/release/`; then beside the ELF, `jab.bin`, objcopy's flat image,
# the bytes the kernel loads, and `provenance.nuon`: the commit, the
# symbols, the flags, the build tool's revision (the checkout's commit, its
# dirty state, and `sdk/nu/jab.nu`'s SHA-256), the toolchain's prefix, its
# version, and the SHA-256 of its assembler, linker, and objcopy, the
# ELF's SHA-256 and the loaded bytes'. A gate before anything measures it:
# the ELF's SHA-256 the one `expected` names, unless `expected` is "".
# DEBUG is refused, since a measured kernel is a release one. Run under
# the real nu: `nu export.nu <repo> <commit> <cands> <symbols> <expected>`,
# the symbols comma separated, "" for none.

def main [repo: string, commit: string, cands: string, symbols: string, expected: string] {
    let full = (^git -C $repo rev-parse $commit | complete | get stdout | str trim)
    if $full == "" { error make { msg: $"($commit) names no commit in ($repo)" } }
    let short = ($full | str substring 0..<7)
    let names = ($symbols | split row "," | each {|s| $s | str trim } | where {|s| $s != "" } | each {|s| $s | str screaming-snake-case } | uniq | sort)
    if "DEBUG" in $names { error make { msg: "an export is a release build; DEBUG is not one of its symbols" } }
    let label = (if ($names | is-empty) { "" } else { "-" + ($names | str lowercase | str join "-") })
    let dir = ($cands | path expand | path join $"kexport_($short)($label)")
    if ($dir | path exists) { error make { msg: $"($dir) exists; an export is made once" } }
    mkdir $dir
    let tar = ($dir | path join "export.tar")
    let archived = (^git -C $repo archive --format=tar -o $tar $full kernel/src kernel/kernel.jab.toml sdk/src | complete)
    if $archived.exit_code != 0 { error make { msg: $"git archive of ($full): ($archived.stderr)" } }
    let unpacked = (^tar -xf $tar -C $dir | complete)
    if $unpacked.exit_code != 0 { error make { msg: $"tar -x of ($tar): ($unpacked.stderr)" } }
    let kernel = ($dir | path join "kernel")
    let original = (open ($kernel | path join "kernel.jab.toml"))
    $original | reject -o do | upsert workspace ($repo | path expand) | to toml | save --raw -f ($kernel | path join "kernel.jab.toml")
    {
        commit: $full,
        symbols: $names,
        exported_from: $"git archive of kernel/src, kernel/kernel.jab.toml, and sdk/src at ($full), the manifest's workspace the checkout's for the toolchain and the target, its do dropped",
    } | to nuon --indent 2 | save --raw ($kernel | path join "source.nuon")
    let tool = ($repo | path join "sdk" "nu" "jab.nu")
    let built = (if ($names | is-empty) { ^nu $tool build $kernel --kernel | complete } else { ^nu $tool build $kernel --kernel --set ($names | str join ",") | complete })
    if $built.exit_code != 0 { error make { msg: $"the release build of ($kernel): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
    let out = ($kernel | path join "release")
    let elf = ($out | path join "jab.elf")
    if not ($elf | path exists) { error make { msg: $"no jab.elf at ($out): the export must lie in the checkout's target, where its build lands beside it" } }
    let flags = (open --raw ($out | path join "flags") | decode | lines | first)
    if ($flags =~ '--defsym DEBUG=') { error make { msg: $"the export built with DEBUG: ($flags)" } }
    let missing = ($names | where {|n| not ($flags | str contains $"--defsym ($n)=1") })
    if not ($missing | is-empty) { error make { msg: $"the export's flags lack ($missing | str join ', '): ($flags)" } }
    let prefix = ($flags | split row " " | last)
    let tool_of = {|name: string| let p = ($"($prefix)($name)" | path expand); { path: $p, sha256: (open --raw $p | into binary | hash sha256) } }
    let bin = ($out | path join "jab.bin")
    let copied = (^$"($prefix)objcopy" -O binary $elf $bin | complete)
    if $copied.exit_code != 0 { error make { msg: $"objcopy of ($elf): ($copied.stderr)" } }
    let elf_sha = (open --raw $elf | into binary | hash sha256)
    let loaded_sha = (open --raw $bin | into binary | hash sha256)
    let checkout = (^git -C $repo rev-parse HEAD | complete | get stdout | str trim)
    let dirty = ((^git -C $repo status --porcelain | complete | get stdout | str trim) != "")
    {
        commit: $full,
        symbols: $names,
        source: $"kernel/src and kernel/kernel.jab.toml at ($full)",
        sdk: $"sdk/src at ($full), the export's own",
        build_tool: { checkout: $checkout, dirty: $dirty, jab_nu_sha256: (open --raw $tool | into binary | hash sha256) },
        toolchain: {
            prefix: $prefix,
            version: (^$"($prefix)as" --version | complete | get stdout | lines | get -o 0),
            assembler: (do $tool_of "as"),
            linker: (do $tool_of "ld"),
            objcopy: (do $tool_of "objcopy"),
        },
        flags: $flags,
        elf_sha256: $elf_sha,
        loaded_sha256: $loaded_sha,
    } | to nuon --indent 2 | save --raw -f ($out | path join "provenance.nuon")
    if $expected != "" and $elf_sha != $expected {
        error make { msg: $"the export's kernel has SHA-256 ($elf_sha) where ($expected) was expected" }
    }
    print $"export: ($elf), SHA-256 ($elf_sha), loaded ($loaded_sha)(if $expected == '' { '' } else { ', as expected' })"
}
