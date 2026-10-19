use (path self ../../../../../jab/nu/mod/target)

# jab, checked out beside the workbench
const JAB = (path self ../../../../../jab | path expand)

# The debug tree's kernel, fierce image, and still copy's disk in jab's target
export def main []: nothing -> record<kernel: string, image: string, disk: string> {
    let dbg = (target root $JAB | path join debug)
    {
        kernel: ($dbg | path join kernel jab.elf)
        image: ($dbg | path join kit fierce fierce.jab)
        disk: ($dbg | path join kit fierce still.romfs)
    }
}
