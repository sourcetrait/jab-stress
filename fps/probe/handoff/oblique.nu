# Probe of IntervalPhase's oblique pose: the handoff fixture's long wall
# seen from `eye` (x, y, yaw) under partial residency on `slots` slots at
# each level of `levels`, under `lighting`, each run's last count line,
# its window's rows, and its screen, with the tiled and held references.
use ../../../../jab/nu/mod/launch
use ../../../../jab/kit/fierce/test/pose.nu
use ../../../../jab/kit/fierce/nu/mod/console
use ../../../../jab/kit/fierce/nu/mod/gauge

const POOL_LIFTED = 1
const POOL_ONCE = 8

def level-frame [bright: bool, held: bool, --parity, --gradient]: nothing -> binary {
    let flag = {|on: bool| if $on { 0x[01] } else { 0x[00] } }
    [("L" | into binary), 0x[00 00 00], (do $flag $bright), (do $flag $held), (do $flag $gradient), (do $flag $parity), (0..<56 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def raise-frame [levels: int, --stamp]: nothing -> binary {
    [("M" | into binary), 0x[00 00 00], ($levels | into binary | bytes at 0..<1), (if $stamp { 0x[01] } else { 0x[00] }), (0..<58 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def pool-frame [--modes: int = 0, --cold, --slots: int = 0]: nothing -> binary {
    let word = {|v: int| $v | into binary | bytes at 0..<4 }
    [("O" | into binary), 0x[00 00 00], ($modes | into binary | bytes at 0..<1), 0x[00], (if $cold { 0x[01] } else { 0x[00] }), 0x[00], (do $word $slots), (do $word 0), (do $word 0), (do $word 0), (0..<40 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def main [kernel: path, image: path, disk: path, out: path, spec: string] {
    let s = ($spec | from nuon)
    let place = { name: "oblique", x: $s.x, y: $s.y, z: 1.6, yaw: $s.yaw, pitch: 0 }
    let placed = (pose pose-frame $place)
    let ended = (pose command-frame "E")
    let legs = [{ name: "start", places: [], pad: [] }, { name: "first", places: [$place], pad: [] }, { name: "second", places: [$place], pad: [] }]
    let light = {|held: bool| if $s.lighting == "gradient" { level-frame false $held --gradient } else { level-frame false $held --parity } }
    let rows = ($s.levels | each {|l|
        let kinds = ([held tiled partial] | each {|kind|
            let sends = (match $kind {
                "held" => [{ at: 1400ms, bytes: (do $light true) }, { at: 1400ms, bytes: (raise-frame $l --stamp) }]
                "tiled" => [{ at: 1400ms, bytes: (do $light false) }, { at: 1400ms, bytes: (raise-frame $l --stamp) }]
                _ => [
                    { at: 1300ms, bytes: (console workers 0 0) }
                    { at: 1400ms, bytes: (do $light false) }
                    { at: 1400ms, bytes: (raise-frame $l --stamp) }
                    { at: 1800ms, bytes: (pool-frame --modes ($POOL_LIFTED + $POOL_ONCE) --cold --slots $s.slots) }
                ]
            })
            let all = ($sends | append [{ at: 1500ms, bytes: $placed }, { at: 2300ms, bytes: $placed }, { at: 3800ms, bytes: $ended }] | sort-by at)
            let dir = ($out | path join $"($s.lighting)_($l)_($kind)")
            let run = (launch --kernel $kernel --image $image --out $dir --set "DEBUG,COUNT" --sound --api --disk $disk --serial "fps" --send $all --screen 3500ms --seconds 5)
            let m = (gauge measure $run.api $legs)
            let window = ($m.rows | where leg == "second")
            let counts = ($run.serial | lines | where {|x| $x starts-with "fps: count" } | last)
            {
                kind: $kind, screen: $run.screen, complete: $m.complete, valid: $m.valid,
                slots_used: ($window | get -o slots_used | uniq), tiled_pixels: ($window | get -o tiled_pixels | uniq | first 3),
                built: ($window | get -o tiles_built | math sum), counts: $counts,
            }
        })
        { level: $l, runs: $kinds }
    })
    $rows | to nuon | save -f ($out | path join "oblique.nuon")
    print ($rows | each {|r| { level: $r.level, partial: ($r.runs | where kind == "partial" | get 0 | reject screen) } } | to nuon)
}
