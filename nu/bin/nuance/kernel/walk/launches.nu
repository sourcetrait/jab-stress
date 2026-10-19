#!/usr/bin/env nu
# The launches module's path, bound at parse time
const LAUNCHES = path self ../../../../mod/kernel/walk/launches
use $LAUNCHES

# walk's own CADENCE_TEST launches against a Jab checkout
def main [jab_dir: path, scratch: path, --only: string = ""] {
    launches $jab_dir $scratch --only $only
}
