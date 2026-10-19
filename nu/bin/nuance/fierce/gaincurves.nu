#!/usr/bin/env nu
# The gaincurves module's path, bound at parse time
const GAINCURVES = path self ../../../mod/fierce/gaincurves
use $GAINCURVES

# A battery's gain curves saved to `out` and summarised
def main [mode: string, base: string, out: string, ...labels: string] {
    gaincurves $mode $base $out ...$labels
}

# A saved reading's builds printed as a markdown table
def "main table" [reading: string, ...builds: string] {
    gaincurves show $reading ...$builds
}
