#!/usr/bin/env nu
# The workerparity module's path, bound at parse time
const WORKERPARITY = path self ../../../mod/fierce/workerparity
use $WORKERPARITY

# A still copy's views drawn by each mode and judged against W 0's
def main [kernel: path, image: path, out: path, --set: string = "debug", --poses: string = "spawn,bay,up", --modes: string = "0:0,2:0,1:0,2:16", --map: string = "render_0", --harts: int = 4, --bootargs: string = "", --cancel] {
    workerparity $kernel $image $out --set $set --poses $poses --modes $modes --map $map --harts $harts --bootargs $bootargs --cancel=$cancel
}

# A parity judged again from its recorded launches, the old verdict kept
def "main judge" [out: path, --cancel, --harts: int = 4, --bootargs: string = ""] {
    workerparity rejudge $out --cancel=$cancel --harts $harts --bootargs $bootargs
}

# A worker's fault at each count, the run ended through the kernel
def "main fault" [kernel: path, image: path, out: path, --set: string = "debug", --pose: string = "spawn", --modes: string = "1:0,2:0,3:0,4:0,5:0,6:0,7:0", --map: string = "render_0", --harts: int = 8, --bootargs: string = "", --started: string = ""] {
    workerparity fault $kernel $image $out --set $set --pose $pose --modes $modes --map $map --harts $harts --bootargs $bootargs --started $started
}
