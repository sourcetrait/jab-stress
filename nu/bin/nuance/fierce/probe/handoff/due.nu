#!/usr/bin/env nu
# The due module's path, bound at parse time
const DUE = path self ../../../../../mod/nuance/fierce/probe/handoff/due
use $DUE

# The launch module's due order over its cases, printed as NUON
def main [] {
    due 
}
