# Probe of DumpIntegrity's and DumpRecordKinds' fixtures: the run's own
# capture and its alterations, each read by tiles.nu's dumps; the cases
# mirror test.nu's dump-alterations.
use ../../../../jab/game/fps/test/tiles.nu [dumps]

def rec [api: binary, i: int]: nothing -> binary { $api | bytes at ($i * 64)..<(($i + 1) * 64) }
def splice [api: binary, i: int, n: int, put: binary]: nothing -> binary {
    [($api | bytes at 0..<($i * 64)), $put, ($api | bytes at (($i + $n) * 64)..)] | bytes collect
}
def word-at [r: binary, at: int, v: int]: nothing -> binary {
    [($r | bytes at 0..<$at), ($v | into binary | bytes at 0..<4), ($r | bytes at ($at + 4)..)] | bytes collect
}

def main [api: path] {
    let a = (open --raw $api | into binary)
    let aligned = {|kind: int| $a | bytes index-of --all ($kind | into binary | bytes at 0..<4) | where {|o| ($o mod 64) == 0 } | each {|o| $o // 64 } }
    let h = (do $aligned 16 | first)
    let answers = (do $aligned 11 | where {|i| ((rec $a $i) | bytes at 4..<8 | into int --endian little) == 68 })
    let answer = ($answers | first)
    let closing = ($answers | last)
    let t = ($h + 6)
    let r = (rec $a $t)
    let first = ($r | bytes at 8..<12 | into int --endian little)
    let slot = ($r | bytes at 4..<8 | into int --endian little)
    let last = ($h + 342)
    let cases = [
        { name: "control", expect: "", bytes: $a }
        { name: "header_schema", expect: "header schema", bytes: (splice $a $h 1 (word-at (rec $a $h) 60 4)) }
        { name: "dropped", expect: "missing", bytes: (splice $a $t 1 0x[]) }
        { name: "repeated", expect: "repeated", bytes: (splice $a $t 1 ([$r, $r] | bytes collect)) }
        { name: "swapped", expect: "order", bytes: (splice $a $t 2 ([(rec $a ($t + 1)), $r] | bytes collect)) }
        { name: "slot", expect: "slot", bytes: (splice $a $t 1 (word-at $r 4 ($slot + 1))) }
        { name: "schema", expect: "schema", bytes: (splice $a $t 1 (word-at $r 60 4)) }
        { name: "first", expect: "first texel", bytes: (splice $a $t 1 (word-at $r 8 ($first + 1))) }
        { name: "padding", expect: "padding", bytes: (splice $a $last 1 (word-at (rec $a $last) 28 1)) }
        { name: "tail_dropped", expect: "count", bytes: (splice $a $last 1 0x[]) }
        { name: "orphan_before", expect: "orphan", bytes: (splice $a 0 0 $r) }
        { name: "orphan_after", expect: "orphan", bytes: (splice $a ($answer + 1) 0 $r) }
        { name: "truncated", expect: "truncated", bytes: ($a | bytes at 0..<((($h + 100) * 64) + 30)) }
        { name: "unfinished", expect: "unfinished", bytes: ($a | bytes at 0..<(($h + 100) * 64)) }
        { name: "kind_high", expect: "foreign", bytes: (splice $a $t 1 (word-at $r 0 273)) }
        { name: "foreign_inserted", expect: "foreign", bytes: (splice $a ($t + 1) 0 (word-at $r 0 18)) }
        { name: "answer_command", expect: "unfinished", bytes: (splice $a $closing 1 (word-at (rec $a $closing) 4 324)) }
    ]
    let rows = ($cases | each {|c|
        let s = (date now)
        let read = (dumps $c.bytes)
        let reasons = ($read.problems | get -o reason | default [] | uniq)
        { name: $c.name, ok: (if $c.expect == "" { $reasons | is-empty } else { $c.expect in $reasons }), reasons: ($reasons | str join ","), tiles: ($read.dumps | each {|d| $d | length } | str join " "), ms: (((date now) - $s) / 1ms | into int) }
    })
    print ({ header: $h, answer: $answer, closing: $closing, records: (($a | bytes length) // 64) } | to nuon)
    print ($rows | to nuon)
}
