#!/usr/bin/env nu
# The litsteps module's path, bound at parse time
const LITSTEPS = path self ../../../../../mod/nuance/fierce/probe/handoff/litsteps
use $LITSTEPS

# The most a capture steps between neighbours along a rectangle's rows
def main [capture: path, rect: string, crosshair: int] {
    litsteps $capture $rect $crosshair
}
