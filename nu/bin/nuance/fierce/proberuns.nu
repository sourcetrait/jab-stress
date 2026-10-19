#!/usr/bin/env nu
# The proberuns module's path, bound at parse time
const PROBERUNS = path self ../../../mod/fierce/proberuns
use $PROBERUNS

# ProbeRuns' reading of the probed batches under `base`, saved
def main [base: string, out: string, ...labels: string, --eps: int = 10000] {
    proberuns $base $out ...$labels --eps $eps
}

# The observer sets' reading under `base`, probed against plain, saved
def "main observer" [base: string, out: string, --probed: string, --plain: string] {
    proberuns observer-sets $base $out --probed $probed --plain $plain
}
