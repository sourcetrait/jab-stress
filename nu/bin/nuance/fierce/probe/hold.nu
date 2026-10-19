#!/usr/bin/env nu
# The hold module's path, bound at parse time
const HOLD = path self ../../../../mod/nuance/fierce/probe/hold
use $HOLD

# W 2 in fixed bands with worker 2 held to the join, or unheld, read back
def main [kernel: path, image: path, disk: path, out: path, --name: string = "hold", --no-hold, --seconds: int = 8, --no-capture] {
    hold $kernel $image $disk $out --name $name --no-hold=$no_hold --seconds $seconds --no-capture=$no_capture
}

# The hold on jab's debug tree, or on another image beside its kernel and disk
def "main on-debug" [out: path, --image: string = "", --name: string = "hold", --no-hold, --seconds: int = 8, --no-capture] {
    hold on-debug $out --image $image --name $name --no-hold=$no_hold --seconds $seconds --no-capture=$no_capture
}
