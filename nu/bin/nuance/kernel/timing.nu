#!/usr/bin/env nu
# The timing module's path, bound at parse time
const TIMING = path self ../../../mod/kernel/timing
use $TIMING

# The decision over one readings record, written as decision.nuon
def main [readings: path, out: path] {
    timing $readings $out
}
