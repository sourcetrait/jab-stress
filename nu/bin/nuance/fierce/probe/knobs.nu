#!/usr/bin/env nu
# The knobs module's path, bound at parse time
const KNOBS = path self ../../../../mod/nuance/fierce/probe/knobs
use $KNOBS

# The pool's knobs probed in one mode on the debug build, probe.nuon kept
def main [mode: string, out: path, --seconds: int = 10] {
    knobs $mode $out --seconds $seconds
}
