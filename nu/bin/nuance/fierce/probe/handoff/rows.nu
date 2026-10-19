#!/usr/bin/env nu
# The rows module's path, bound at parse time
const ROWS = path self ../../../../../mod/nuance/fierce/probe/handoff/rows
use $ROWS

# A handoff run's last rows of the pool's counters, printed as NUON
def main [api: path] {
    rows $api
}
