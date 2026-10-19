#!/usr/bin/env nu
# The tilecensus module's path, bound at parse time
const TILECENSUS = path self ../../../mod/fierce/tilecensus
use $TILECENSUS

# TileCensus's reading saved to `out` and summarised
def main [base: string, out: string, ...labels: string] {
    tilecensus $base $out ...$labels
}
