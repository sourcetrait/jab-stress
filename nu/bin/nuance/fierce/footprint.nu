#!/usr/bin/env nu
# The footprint module's path, bound at parse time
const FOOTPRINT = path self ../../../mod/fierce/footprint
use $FOOTPRINT

# An export's debug images built with their kernels, provenance, and IZ_MIN
def "main images" [export: path] {
    footprint images $export
}

# Each pose captured on its kind's images, then referenced and differed
def "main capture" [export: path, poses: path, out: path, --only: string = ""] {
    footprint capture $export $poses $out --only $only
}

# Every captured pose judged against the pose set, reading.nuon written
def "main read" [out: path, poses: path] {
    footprint read $out $poses
}

# The clamp's threshold and witnesses planned over a captured pose
def "main clamp-plan" [dir: path, surface: int, --owner: string = "owner", --levels: string = "levels"] {
    footprint clamp-plan $dir $surface --owner $owner --levels $levels
}

# Each region where a pose's pictures differ cut out of both as PNGs
def "main crops" [out: path, pose: string, --pad: int = 16] {
    footprint crops $out $pose --pad $pad
}

def main [] { help main }
