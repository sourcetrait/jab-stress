#!/usr/bin/env nu
# The freeze module's path, bound at parse time
const FREEZE = path self ../../../mod/fierce/freeze
use $FREEZE

# A commit's program exported, built, and gated, its provenance kept
def main [repo: string, commit: string, cands: string, expected: string, --set: string = "", --program: string = "", --debug] {
    freeze $repo $commit $cands $expected --set $set --program $program --debug=$debug
}

# The launcher a freeze's measurements run under, written once to `out`
def "main launcher" [repo: string, out: path] {
    freeze launcher $repo $out
}
