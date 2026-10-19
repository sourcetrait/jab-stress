#!/usr/bin/env nu
# The walk module's path, bound at parse time
const WALK = path self ../../../mod/kernel/walk
use $WALK

# A probed run's bundle checked and its guest's side read, saved
def main [probe: path, out: path, --eps: int = 10000] {
    walk $probe $out --eps $eps
}

# An unprobed run read from its own records, guest-only, saved
def "main guest" [run: path, out: path, --eps: int = 10000] {
    walk guest $run $out --eps $eps
}

# A replay stream written from a run's own records
def "main replay-of" [run: path, stream: path] {
    walk replay-of $run $stream
}
