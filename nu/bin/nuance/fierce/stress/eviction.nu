#!/usr/bin/env nu
# The eviction module's path, bound at parse time
const EVICTION = path self ../../../../mod/fierce/stress/eviction
use $EVICTION

# The eviction fixtures named, every one by default, each result kept
def main [kernel: path, image: path, disk: path, out: path, ...fixtures: string] {
    eviction $kernel $image $disk $out ...$fixtures
}

# The fixtures on jab's debug tree, or another image beside its kernel and disk
def "main on-debug" [out: path, ...fixtures: string, --image: string = ""] {
    eviction on-debug $out ...$fixtures --image $image
}
