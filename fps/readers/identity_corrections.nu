# IdentityCorrections (FrameCeiling.md, TwoWorkers' audit): an audited
# correction beside each identity of WorkerGauge's batteries, whose build
# flags were read from a debug build's `flags` left in the shared scratch
# images directory, and whose ELF hash is null, the ELF copies renamed.
# Every identity under `<base>/<battery>/<batch>/run_<n>/` is checked
# first: its flags the debug line given, its ELF hash null, its image's
# SHA-256 the file's, and the image's ELF beside it, `<stem>.elf`, holding
# no debug-only symbol; then a sidecar binds to the identity file's
# SHA-256 and the image's, holds build.flags (the debug line to the
# release tree's) and build.elf_sha256 (null to the ELF's), and records
# the evidence; then each is read back through gauge.nu's correction-of.
# The identities stay as written. Run under the real nu from a scratch
# justfile: `nu identity_corrections.nu <base> <release flags file> <nm>
# <out.nuon> <battery>...`.

use ../../../jab/kit/fierce/nu/mod/gauge

# the symbols only a debug build of fps carries (workers.S)
const DEBUG_ONLY = [msg_workers msg_lost_bands msg_unjoined job_delay job_delay_us]

def main [base: string, release_flags_file: string, nm: string, out: string, ...batteries: string] {
    let release_flags = (open --raw $release_flags_file | decode | lines | first)
    if ($release_flags =~ '--defsym DEBUG=') { error make { msg: $"($release_flags_file) is a debug build's: ($release_flags)" } }
    let files = ($batteries | each {|b| glob ($base | path join $b "*" "run_*" "identity.nuon") } | flatten | sort)
    let checked = ($files | each {|file|
        let id = (open $file)
        let image = $id.build.image
        let image_sha = (open --raw $image | into binary | hash sha256)
        if $image_sha != $id.build.image_sha256 { error make { msg: $"($file): the image ($image) has SHA-256 ($image_sha) where the identity records ($id.build.image_sha256)" } }
        if not ($id.build.flags =~ '--defsym DEBUG=') { error make { msg: $"($file): its flags are no debug build's: ($id.build.flags)" } }
        if $id.build.elf_sha256 != null { error make { msg: $"($file): its ELF hash is recorded, ($id.build.elf_sha256)" } }
        let elf = ($image | path dirname | path join $"($image | path parse | get stem).elf")
        let symbols = (^$nm $elf | complete | get stdout | lines | each {|l| $l | split row " " | last })
        let found = ($DEBUG_ONLY | where {|s| $s in $symbols })
        if not ($found | is-empty) { error make { msg: $"($elf) holds the debug-only ($found | str join ', ')" } }
        { file: $file, image: $image, image_sha: $image_sha, old_flags: $id.build.flags, elf: $elf, elf_sha: (open --raw $elf | into binary | hash sha256), symbols: ($symbols | length) }
    })
    let written = (date now | format date "%Y-%m-%dT%H:%M:%S%z")
    let corrected = ($checked | each {|c|
        let sidecar = ($c.file | path dirname | path join "identity_correction.nuon")
        if ($sidecar | path exists) { error make { msg: $"($sidecar) exists" } }
        {
            identity_sha256: (open --raw $c.file | into binary | hash sha256),
            image_sha256: $c.image_sha,
            fields: {
                "build.flags": { old: $c.old_flags, new: $release_flags },
                "build.elf_sha256": { old: null, new: $c.elf_sha },
            },
            evidence: {
                written: $written,
                why: "the build's flags were read from a debug build's `flags` left in the images directory the copied release image sat in, and its ELF hash was null, the ELF copied under another name",
                image: $c.image,
                elf: $c.elf,
                debug_only_symbols_absent: $DEBUG_ONLY,
                elf_symbols: $c.symbols,
                release_flags_from: $release_flags_file,
            },
        } | to nuon --indent 2 | save --raw $sidecar
        let read = (gauge identity corrected $c.file)
        if $read.identity.build.flags != $release_flags or $read.identity.build.elf_sha256 != $c.elf_sha {
            error make { msg: $"($c.file): read back through correction-of as ($read.identity.build | select flags elf_sha256 | to nuon)" }
        }
        { file: $c.file, image_sha256: $c.image_sha, elf_sha256: $c.elf_sha, sidecar: $sidecar }
    })
    { written: $written, release_flags: $release_flags, count: ($corrected | length), corrected: $corrected } | to nuon --indent 1 | save --raw -f $out
    print $"identity corrections: ($corrected | length) sidecars written and read back; ($out)"
}
