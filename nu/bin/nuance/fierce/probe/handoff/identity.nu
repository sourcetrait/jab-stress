#!/usr/bin/env nu
# The identity module's path, bound at parse time
const IDENTITY = path self ../../../../../mod/nuance/fierce/probe/handoff/identity
use $IDENTITY

# The held-off views drawn by two images and held byte for byte
def main [kernel: path, base: path, new: path, handoff_disk: path, still_disk: path, out: path] {
    identity $kernel $base $new $handoff_disk $still_disk $out
}
