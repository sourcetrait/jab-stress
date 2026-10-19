#!/usr/bin/env nu
# The footprint module's path, bound at parse time
const FOOTPRINT = path self ../../../mod/fierce/footprint
use $FOOTPRINT

# An export's five debug images built with their kernels and provenance
def "main images" [export: path] {
    footprint images $export
}

# Each pose captured on every image, then referenced and differed
def "main capture" [export: path, poses: path, out: path, --only: string = ""] {
    footprint capture $export $poses $out --only $only
}

# Every captured pose judged, reading.nuon written
def "main read" [out: path] {
    footprint read $out
}

# Each region where a pose's pictures differ cut out of both as PNGs
def "main crops" [out: path, pose: string, --pad: int = 16] {
    footprint crops $out $pose --pad $pad
}

def main [] { help main }
