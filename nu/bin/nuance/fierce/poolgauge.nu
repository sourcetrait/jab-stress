#!/usr/bin/env nu
# The poolgauge module's path, bound at parse time
const POOLGAUGE = path self ../../../mod/fierce/poolgauge
use $POOLGAUGE

# PoolCore's reading saved to `out` and summarised, or refused
def main [mode: string, base: string, out: string, ...labels: string] {
    poolgauge $mode $base $out ...$labels
}
