#!/usr/bin/env nu
# The workergauge module's path, bound at parse time
const WORKERGAUGE = path self ../../../mod/fierce/workergauge
use $WORKERGAUGE

# WorkerGauge's reading saved to `out` and summarised
def main [mode: string, base: string, out: string, ...labels: string] {
    workergauge $mode $base $out ...$labels
}
