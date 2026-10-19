#!/usr/bin/env nu
# The eviction module's path, bound at parse time
const EVICTION = path self ../../../../mod/nuance/fierce/probe/eviction
use $EVICTION

# The probe in one mode under a slot cap, every settle dumped and read back
def main [kernel: path, image: path, disk: path, out: path, mode: string, slots: int = 0, --view: string = "bay", --cycles: int = 2, --modes: int = 0, --tag: string = ""] {
    eviction $kernel $image $disk $out $mode $slots --view $view --cycles $cycles --modes $modes --tag $tag
}
