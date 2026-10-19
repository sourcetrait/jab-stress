#!/usr/bin/env nu
# The identity_corrections module's path, bound at parse time
const IDENTITY_CORRECTIONS = path self ../../../mod/fierce/identity_corrections
use $IDENTITY_CORRECTIONS

# Each battery identity checked, its correction written and read back
def main [base: string, release_flags_file: string, nm: string, out: string, ...batteries: string] {
    identity_corrections $base $release_flags_file $nm $out ...$batteries
}
