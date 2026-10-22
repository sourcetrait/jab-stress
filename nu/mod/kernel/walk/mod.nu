use (path self ./paired) [paired-reading]
use (path self ./reading) [guest-reading]
use (path self ./replay) [replay-stream]

# A reading's record saved as NUON
def write [record: record, out: path]: nothing -> nothing {
    $record | to nuon --indent 1 | save --raw -f $out
}

# A reading's record printed for reading
def show [record: record]: nothing -> nothing {
    let state = (if $record.valid { "valid" } else if $record.complete { "invalid" } else { "incomplete" })
    let standing = (if $record.historical == true { ", historical, no deciding arm" } else if $record.deciding { ", deciding" } else { "" })
    let stopped = ($record | get -o stage | default "")
    let at = (if $stopped == "" { "" } else { $", stopped at its ($stopped)" })
    print $"walk cadence, ($record.mode): ($state)($standing)($at)"
    for f in $record.faults { print $"  ($f.rule): ($f.held), ($f.examples | str join '; ')" }
    for u in $record.unchecked { print $"  unchecked: ($u)" }
    if $record.reading != null {
        let r = $record.reading
        print $"  ($r.frames) frames over ($r.window_s | math round -p 2) s, ended by ($r.ended_by); presents ($r.presents), K violations ($r.k.violations) at eps ($r.k.eps)"
        print $"  frame interval ($r.frame_interval.median_ms) ms median, ($r.frame_interval.p95_ms) 95th; presented ($r.presented_interval.median_ms) and ($r.presented_interval.p95_ms)"
    }
    let pairing = ($record | get -o pairing)
    if $pairing != null {
        let window = ($pairing.window | default {})
        let stalls = ($pairing.stalls.calls | length)
        let framed = ($pairing.stalls.frame | length)
        print $"  pairing ($pairing.verdict) on ($pairing.bound) bounds, ($window | get -o presents) presents of ($window | get -o uploads) uploads; stalls ($stalls), long frames on their brackets ($framed)"
    }
    let flips = ($record | get -o flips)
    if $flips != null {
        print $"  ($flips.shown) of ($flips.presents) shown, ($flips.superseded) superseded, ($flips.repeated) repeats; host flips ($flips.host_interval.median_ms) ms median, ($flips.host_interval.p95_ms) 95th; age ($flips.age.median_ms) ms"
    }
    for s in ($record | get -o stretches | default []) {
        let located = (if $s.located == null { "no phase located, TIMING off" } else { $s.located | str join ", " })
        print $"  stretch at ($s.at_s | math round -p 2) s, frames ($s.first.frame) to ($s.last.frame), ($s.flips) flips, host ($s.host_interval.median_ms) ms median: ($located)"
    }
}

# A probed run read paired, saved
export def main [probe: path, out: path, --eps: int = 10000, --replay: path] {
    let record = (paired-reading $probe --eps $eps --replay $replay)
    write $record $out
    show $record
}

# An unprobed run read from its own records, guest-only, saved
export def guest [run: path, out: path, --eps: int = 10000, --replay: path] {
    let dir = ($run | path expand)
    let identity = (open --raw ($dir | path join "identity.nuon") | into binary | decode | from nuon)
    let api = ($dir | path join "api.out")
    let bytes = (if ($api | path exists) { open --raw $api | into binary } else { 0x[] })
    let record = (guest-reading $bytes $identity --eps $eps --replay $replay)
    write $record $out
    show $record
}

# Every run under a set's tree read guest-only, each saved as <name>.guest.nuon
export def guest-runs [tree: path, out: path, --eps: int = 10000] {
    let root = ($tree | path expand)
    let runs = (glob ($root | path join "**" "api.out") --no-dir | each {|a| $a | path dirname } | where {|d| $d | path join "identity.nuon" | path exists } | sort)
    if ($runs | is-empty) { error make { msg: $"no run under ($root): no directory there holds an api.out and an identity.nuon" } }
    mkdir $out
    for dir in $runs {
        let rel = ($dir | path relative-to $root)
        let name = (if $rel == "" { $root | path basename } else { $rel | path split | str join "_" })
        let identity = (open --raw ($dir | path join "identity.nuon") | into binary | decode | from nuon)
        let record = (guest-reading (open --raw ($dir | path join "api.out") | into binary) $identity --eps $eps)
        write $record ($out | path join $"($name).guest.nuon")
        print $"--- ($name)"
        show $record
    }
}

# A replay stream written from a run's own records
export def replay-of [run: path, stream: path] {
    let bytes = (open --raw ($run | path expand | path join "api.out") | into binary)
    replay-stream $bytes | save --raw $stream
    print $"replay-of: ($stream), (open --raw $stream | into binary | bytes length) bytes"
}
