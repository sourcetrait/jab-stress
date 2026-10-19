# Probe of the launch module's due-order and its loop's list idioms.
use ../../../../jab/nu/mod/launch

def names [order: list<any>]: nothing -> list<string> {
    $order | each {|a| if $a.kind == "screen" { "screen" } else { $"($a.kind) ($a.index)" } }
}

def main [] {
    let p = { kind: "send", index: 0, at: 2300ms }
    let e = { kind: "send", index: 1, at: 3800ms }
    let late = (names (launch due-order [$p $e] 3500ms 3900ms))
    let tied = (names (launch due-order [{ kind: "send", index: 0, at: 3500ms }, { kind: "send", index: 1, at: 3500ms }] 3500ms 3500ms))
    let early = (names (launch due-order [$p $e] 3500ms 3000ms))
    let none = (names (launch due-order [$p $e] null 3900ms))
    let empty = (names (launch due-order [] 3500ms 3900ms))
    let nothing_due = (names (launch due-order [] null 3900ms))
    let kinds = (names (launch due-order [{ kind: "key", index: 0, at: 1000ms }, { kind: "send", index: 0, at: 900ms }, { kind: "pad", index: 0, at: 1000ms }, { kind: "send", index: 1, at: 1000ms }] null 1100ms))
    mut seconds = ([{ at: 1sec, bytes: 0x[00] }, { at: 2sec, bytes: 0x[01] }] | each --keep-empty {|_| null })
    let i = 1
    $seconds = ($seconds | update $i 2.5)
    let empty_seconds = ([] | each --keep-empty {|_| null })
    print ({ late: $late, tied: $tied, early: $early, none: $none, empty: $empty, nothing_due: $nothing_due, kinds: $kinds, seconds: $seconds, empty_seconds: $empty_seconds } | to nuon)
}
