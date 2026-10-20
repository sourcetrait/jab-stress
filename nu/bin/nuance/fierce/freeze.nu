#!/usr/bin/env nu
# The freeze module's path, bound at parse time
const FREEZE = path self ../../../mod/fierce/freeze
use $FREEZE

# A commit's program exported and built release, or debug with `--debug`, gated, its provenance kept
def main [repo: string, commit: string, cands: string, expected: string, --set: string = "", --program: string = "", --debug] {
    freeze $repo $commit $cands $expected --set $set --program $program --debug=$debug
}

# The launcher a freeze's measurements run under, written once to `out`
def "main launcher" [repo: string, out: path] {
    if ($out | path exists) { error make { msg: $"($out) exists; a freeze's launcher is recorded once" } }
    let l = (freeze launcher-of $repo)
    $l | to nuon --indent 2 | save --raw $out
    print $"launcher: ($l.supervisor.path), SHA-256 ($l.supervisor.sha256), built from ($l.built_from.commit)(if $l.built_from.dirty { ' with changes' } else { '' }); ($out)"
}
