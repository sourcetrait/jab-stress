# The images' record, in the export's own directory
export const IMAGES = "footprint_images.nuon"

# The 1/z floor an image was assembled with: its ELF's IZ_MIN, in 6.26
export def iz-min-of [elf: path, prefix: string]: nothing -> int {
    let listed = (^$"($prefix)nm" $elf | complete)
    if $listed.exit_code != 0 { error make { msg: $"nm of ($elf): ($listed.stderr)" } }
    let found = ($listed.stdout | lines | parse "{value} {type} {name}" | where name == "IZ_MIN")
    if ($found | length) != 1 { error make { msg: $"($elf) carries ($found | length) IZ_MIN symbols, where an image carries one" } }
    $"0x($found | first | get value)" | into int
}
