#!/usr/bin/env nu
# The footprint module's path, bound at parse time
const FOOTPRINT = path self ../../../mod/fierce/footprint
use $FOOTPRINT

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

# A restored run's poses read again, its reading beside the first's
def "main reread" [tree: path, out: path, poses: path] {
    footprint reread $tree $out $poses
}

# The bin's help, its verbs listed, when called with no verb
def main [] { help main }
