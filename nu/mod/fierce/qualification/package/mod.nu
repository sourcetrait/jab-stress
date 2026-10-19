use (path self ../../../../../../jab/nu/mod/build)
use (path self ../../../../../../jab/nu/mod/package)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../matrix)
use (path self ../matrix) [JAB PACKAGED]

# The candidate's export's program directory, the one holding its manifest
def program-of [export: path]: nothing -> string {
    let manifests = (glob ($export | path join "**" "program.jab.toml"))
    if ($manifests | length) != 1 { error make { msg: $"($export) holds ($manifests | length) program manifests, where an export holds one" } }
    $manifests | first | path dirname
}

# A file held to the SHA-256 the candidate names, else refused by name
def held [file: path, sha: string, what: string]: nothing -> string {
    if not ($file | path exists) { error make { msg: $"no ($what) at ($file)" } }
    let found = (open --raw $file | hash sha256)
    if $found != $sha { error make { msg: $"the ($what) ($file) has SHA-256 ($found), where the candidate names ($sha)" } }
    $file
}

# The candidate's host package for a target: its guest artifacts by role from its export, its bench packaged
export def main [candidate: path, export: path, target: string, out: path, --stage: string = ""] {
    let cand = (open --raw $candidate | decode utf-8 | from nuon)
    let target = ($target | str lowercase)
    let export = ($export | path expand)
    let program = (program-of $export)
    let source = (open ($program | path join "source.nuon"))
    if $source.commit != $cand.jab { error make { msg: $"the export at ($export) is of ($source.commit), where the candidate is ($cand.jab)" } }
    let built = (build program-out $program release)
    let image = (held ($built | path join "fierce.jab") $cand.image_sha256 "image")
    let prov = (open ($built | path join "provenance.nuon"))
    if $prov.commit != $cand.jab or $prov.image_sha256 != $cand.image_sha256 { error make { msg: $"the export's provenance names ($prov.commit)'s image ($prov.image_sha256), where the candidate is ($cand.jab)'s ($cand.image_sha256)" } }
    let elf = (held ($built | path join "fierce.elf") $prov.elf_sha256 "image's ELF, by the export's provenance,")
    let kernel = (held (build program-kernel $program release) $cand.kernel_sha256 "kernel")
    let tree = (build program-shard ($JAB | path join "kit" "fierce") "asset" | path join $cand.assets.map)
    let digest = (gauge identity tree-digest $tree)
    if $digest != $cand.assets.digest { error make { msg: $"the asset tree ($tree) has digest ($digest), where the candidate names ($cand.assets.digest)" } }
    let defined = (matrix jab-file $cand.jab $"kit/fierce/bench/qual_($target).nuon")
    if $defined == null { error make { msg: $"jab at ($cand.jab) holds no bench for ($target)" } }
    let route = (matrix jab-file $cand.jab "kit/fierce/nu/nuon/route/route_render_0.nuon")
    if $route == null { error make { msg: $"jab at ($cand.jab) holds no factory route" } }
    let name = $"qual_($target)-($cand.jab | str substring 0..<10)"
    let stage = (if $stage == "" { $out | path expand | path dirname | path join $"($name).stage" } else { $stage | path expand })
    let made = ($stage | path dirname | path join $"($name).inputs")
    if ($made | path exists) { error make { msg: $"($made) exists; a package's inputs are written once" } }
    mkdir $made
    let route_file = ($made | path join "route_render_0.nuon")
    $route | save --raw $route_file
    let bench_file = ($made | path join $"qual_($target).nuon")
    matrix packaged-bench ($defined | from nuon) $target | to nuon --indent 2 | save --raw $bench_file
    let flags = (open --raw ($built | path join "flags") | decode | lines | first)
    let prefix = ($flags | split row " " | last)
    let loaded = ($made | path join "kernel.bin")
    let copied = (^$"($prefix)objcopy" -O binary $kernel $loaded | complete)
    if $copied.exit_code != 0 { error make { msg: $"objcopy of ($kernel): ($copied.stderr)" } }
    let image_dir = ($PACKAGED.image | path dirname)
    let spec = {
        name: $name,
        artifacts: [
            { role: "image", from: $image, at: $PACKAGED.image, meta: { commit: $source.commit, symbols: ($source | get -o symbols | default []), flags: $flags } }
            { role: "elf", from: $elf, at: ($image_dir | path join "fierce.elf") }
            { role: "flags", from: ($built | path join "flags"), at: ($image_dir | path join "flags") }
            { role: "demand", from: ($built | path join "demand.nuon"), at: ($image_dir | path join "demand.nuon") }
            { role: "provenance", from: ($built | path join "provenance.nuon"), at: ($image_dir | path join "provenance.nuon") }
            { role: "source", from: ($program | path join "source.nuon"), at: ($image_dir | path join "source.nuon") }
            { role: "kernel", from: $kernel, at: $PACKAGED.kernel, meta: { elf_sha256: $cand.kernel_sha256, loaded_sha256: (open --raw $loaded | hash sha256) } }
            { role: "assets", from: $tree, at: $PACKAGED.assets, meta: { map: $cand.assets.map, digest: $digest } }
            { role: "route", from: $route_file, at: $PACKAGED.route }
            { role: "bench", from: $bench_file, at: $"bench/qual_($target).nuon" }
        ],
        identities: {
            candidate: { jab: $cand.jab, tag: $cand.tag, file_sha256: (open --raw $candidate | hash sha256) },
            kernel: { elf_sha256: { value: $cand.kernel_sha256, checks: "every run's identity, held to the candidate's kernel" }, loaded_sha256: { value: (open --raw $loaded | hash sha256), checks: "the kernel's release bytes against a baseline's, the loaded flat image alone" } },
            image: { sha256: $cand.image_sha256, elf_sha256: $prov.elf_sha256, tree_elf_sha256: $cand.elf_sha256, checks: "the image's bytes the candidate's; the ELF the export's, its symbol table carrying RELEASE where the candidate's tree build's does not" },
            assets: { map: $cand.assets.map, digest: $digest },
            bench: { target: $target, source: $"kit/fierce/bench/qual_($target).nuon at ($cand.jab)" },
        },
    }
    let spec_file = ($made | path join "spec.nuon")
    $spec | to nuon --indent 2 | save --raw $spec_file
    let result = (package make $spec_file $stage $out)
    print $"qualification: the package ($result.package) for ($target), ($result.artifacts) artifacts, ($result.bytes) bytes, SHA-256 ($result.sha256); run it by extracting it and `./do bench kit/fierce/qual_($target) --package <its directory>`"
    $result
}
