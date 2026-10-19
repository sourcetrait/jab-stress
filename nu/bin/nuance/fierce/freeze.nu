#!/usr/bin/env nu
# The freeze module's path, bound at parse time
const FREEZE = path self ../../../mod/fierce/freeze
use $FREEZE

# A commit's program exported and built release, gated, its provenance kept
def main [repo: string, commit: string, cands: string, expected: string, --set: string = "", --program: string = ""] {
    freeze $repo $commit $cands $expected --set $set --program $program
}
