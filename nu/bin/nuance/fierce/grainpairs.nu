#!/usr/bin/env nu
# The grainpairs module's path, bound at parse time
const GRAINPAIRS = path self ../../../mod/fierce/grainpairs
use $GRAINPAIRS

# A battery's two band heights read as matched pairs, saved and printed
def main [mode: string, base: string, out: string, a: string, b: string, count: int] {
    grainpairs $mode $base $out $a $b $count
}
