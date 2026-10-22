use (path self ../../../../../../jab/nu/mod/build)
use (path self ../../freeze) [symbols-of provenance-of]

# The images an export is built as, each a label, its set, and the poses' kind it serves
const BUILDS = [
    [label, set, kind];
    [picture, "debug", view]
    [picture_candidate, "debug,footprint", view]
    [owner, "debug,owner", view]
    [levels, "debug,levels", view]
    [levels_candidate, "debug,footprint,levels", view]
    [owner_clamp, "debug,iz_test,owner", clamp]
    [levels_clamp, "debug,iz_test,levels", clamp]
    [levels_candidate_clamp, "debug,footprint,iz_test,levels", clamp]
]

# The images' record, in the export's own directory
export const IMAGES = "footprint_images.nuon"

# The 1/z floor an image was assembled with: its ELF's IZ_MIN, an integer in 6.26
export def iz-min-of [elf: path, prefix: string]: nothing -> int {
    let listed = (^$"($prefix)nm" $elf | complete)
    if $listed.exit_code != 0 { error make { msg: $"nm of ($elf): ($listed.stderr)" } }
    let found = ($listed.stdout | lines | parse "{value} {type} {name}" | where name == "IZ_MIN")
    if ($found | length) != 1 { error make { msg: $"($elf) carries ($found | length) IZ_MIN symbols, where an image carries one" } }
    $"0x($found | first | get value)" | into int
}

# The export's program directory, the one holding a manifest
def program-of [export: path]: nothing -> string {
    let manifests = (glob ($export | path join "**" "program.jab.toml"))
    if ($manifests | length) != 1 { error make { msg: $"($export) holds ($manifests | length) program manifests, where an export holds one" } }
    $manifests | first | path dirname
}

# An export's five debug images built with their kernels and provenance
export def images [export: path] {
    let export = ($export | path expand)
    let record = ($export | path join $IMAGES)
    if ($record | path exists) { error make { msg: $"($record) exists; an export's images are made once" } }
    let program = (program-of $export)
    let source = (open ($program | path join "source.nuon"))
    let repo = (open ($program | path join "program.jab.toml") | get workspace)
    let tool = ($repo | path join "nu" "bin" "do.nu")
    let place = ($program | path relative-to $export)
    mut images = []
    for b in $BUILDS {
        let copy = ($export | path dirname | path join $"($export | path basename)_($b.label)")
        if ($copy | path exists) { error make { msg: $"($copy) exists; an image is built once" } }
        let target = ($copy | path join $place)
        mkdir $target
        for item in [src program.jab.toml source.nuon] { cp -r ($program | path join $item) $target }
        let kernel_built = (^nu $tool build ($repo | path join "kernel") --kernel --set $b.set | complete)
        if $kernel_built.exit_code != 0 { error make { msg: $"the ($b.label) kernel's build: ($kernel_built.stdout + $kernel_built.stderr | lines | last 6 | str join ' | ')" } }
        let built = (^nu $tool build $target --set $b.set | complete)
        if $built.exit_code != 0 { error make { msg: $"the ($b.label) build of ($target): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
        let out = (build program-out $target debug)
        let name = (open ($target | path join "program.jab.toml") | get name)
        let image = ($out | path join $"($name).jab")
        if not ($image | path exists) { error make { msg: $"no ($name).jab at ($out)" } }
        let names = (symbols-of $b.set)
        let flags = (open --raw ($out | path join "flags") | decode | lines | first)
        let missing = ($names | where {|n| not ($flags | str contains $"--defsym ($n)=1") })
        if not ($missing | is-empty) { error make { msg: $"the ($b.label) build's flags lack ($missing | str join ', '): ($flags)" } }
        let kernel = ($out | path join "kernel.elf")
        cp (build program-kernel $target debug) $kernel
        let prefix = ($flags | split row " " | last)
        let bin = ($out | path join "kernel.bin")
        let copied = (^$"($prefix)objcopy" -O binary $kernel $bin | complete)
        if $copied.exit_code != 0 { error make { msg: $"objcopy of ($kernel): ($copied.stderr)" } }
        let provenance = (provenance-of $repo $source.commit $image $names)
        let entry = {
            label: $b.label, set: $b.set, kind: $b.kind, symbols: $names, image: $image, image_sha256: $provenance.image_sha256,
            elf_sha256: $provenance.elf_sha256, iz_min: (iz-min-of ($out | path join $"($name).elf") $prefix),
            kernel: $kernel, kernel_sha256: (open --raw $kernel | into binary | hash sha256),
            kernel_loaded_sha256: (open --raw $bin | into binary | hash sha256), flags: $flags,
        }
        $images = ($images | append $entry)
        print $"($b.label): ($image), SHA-256 ($entry.image_sha256), IZ_MIN ($entry.iz_min), the kernel's loaded bytes ($entry.kernel_loaded_sha256)"
    }
    let loaded = ($images | get kernel_loaded_sha256 | uniq)
    if ($loaded | length) != 1 { error make { msg: $"the images' kernels load different bytes: ($images | select label kernel_loaded_sha256 | to nuon)" } }
    { export: $export, commit: $source.commit, images: $images } | to nuon --indent 2 | save --raw $record
    print $"footprint images: ($images | length) built from ($source.commit), one kernel's code under all"
}
