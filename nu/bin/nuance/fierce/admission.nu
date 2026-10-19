#!/usr/bin/env nu
# The admission module's path, bound at parse time
const ADMISSION = path self ../../../mod/fierce/admission
use $ADMISSION

# The admission reading of the batches under `base`, saved and printed
def main [base: path, out: path, ...labels: string] {
    admission $base $out ...$labels
}
