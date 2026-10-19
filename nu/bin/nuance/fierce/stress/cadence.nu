#!/usr/bin/env nu
# The cadence module's path, bound at parse time
const CADENCE = path self ../../../../mod/fierce/stress/cadence
use $CADENCE

# The cadence fixtures alone on a debug image, `cadence: ok` once they hold
def main [kernel: path, image: path, out: path] {
    cadence $kernel $image $out
}
