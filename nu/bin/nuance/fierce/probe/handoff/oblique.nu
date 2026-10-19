#!/usr/bin/env nu
# The oblique module's path, bound at parse time
const OBLIQUE = path self ../../../../../mod/nuance/fierce/probe/handoff/oblique
use $OBLIQUE

# The oblique pose's held, tiled, and partial runs at each level
def main [kernel: path, image: path, disk: path, out: path, spec: string] {
    oblique $kernel $image $disk $out $spec
}
