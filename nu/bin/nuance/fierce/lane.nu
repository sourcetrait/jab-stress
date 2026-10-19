#!/usr/bin/env nu
# The lane module's path, bound at parse time
const LANE = path self ../../../mod/fierce/lane
use $LANE

# The cadence lane's summary of the batches under `base`, saved
def main [base: string, out: string, ...labels: string] {
    lane $base $out ...$labels
}
