#!/usr/bin/env nu
# The layout module's path, bound at parse time
const LAYOUT = path self ../../../../mod/nuance/fierce/probe/layout
use $LAYOUT

# Each case's candidate tree written from the game's src at a commit
def main [cands: path, commit: string, ...names: string] {
    layout $cands $commit ...$names
}
