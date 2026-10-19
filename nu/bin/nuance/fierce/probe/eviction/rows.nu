#!/usr/bin/env nu
# The rows module's path, bound at parse time
const ROWS = path self ../../../../../mod/nuance/fierce/probe/eviction/rows
use $ROWS

# The pool's counters a frame from a capture, from its own configuration on
def main [api: path] {
    rows $api
}
