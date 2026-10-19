#!/usr/bin/env nu
# The resolve module's path, bound at parse time
const RESOLVE = path self ../../../../mod/fierce/tilecensus/resolve
use $RESOLVE

# Each run request resolved, the answers printed as NUON
def main [requests: string] {
    resolve $requests
}
