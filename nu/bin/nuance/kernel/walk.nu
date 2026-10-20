#!/usr/bin/env nu
# The walk module's path, bound at parse time
const WALK = path self ../../../mod/kernel/walk
# The box series' controls' module's path, bound at parse time
const CONTROLS = path self ../../../mod/kernel/walk/controls
use $WALK
use $CONTROLS

# A probed run read paired, saved
def main [probe: path, out: path, --eps: int = 10000, --replay: path] {
    walk $probe $out --eps $eps --replay $replay
}

# An unprobed run read from its own records, guest-only, saved
def "main guest" [run: path, out: path, --eps: int = 10000, --replay: path] {
    walk guest $run $out --eps $eps --replay $replay
}

# Every run under a set's tree read guest-only, each saved as <name>.guest.nuon
def "main guest-runs" [tree: path, out: path, --eps: int = 10000] {
    walk guest-runs $tree $out --eps $eps
}

# A replay stream written from a run's own records
def "main replay-of" [run: path, stream: path] {
    walk replay-of $run $stream
}

# A box series read whole: every run, each control's effects, the images
def "main controls" [base: path, out: path, --expected: string = "{}"] {
    controls $base $out --expected $expected
}
