#!/usr/bin/env nu
# The freeze module's path, bound at parse time
const FREEZE = path self ../../../mod/kernel/freeze
use $FREEZE

# A commit's kernel exported and built release, gated, its provenance kept
def main [repo: string, commit: string, cands: string, symbols: string, expected: string] {
    freeze $repo $commit $cands $symbols $expected
}
