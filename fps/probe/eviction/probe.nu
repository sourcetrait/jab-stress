# TileEviction's planning probe: the still copy's spawn view (A) and the
# same eye turned about (B), placed in turn under a slot cap, every
# settle dumped (D, every surface), the tiles' keys, slots, generations,
# and texel signatures read back with the pool's counters a frame.
use ../../../../jab/sdk/nu/jab.nu
use ../../../../jab/game/fps/test/pose.nu
use ../../../../jab/game/fps/test/gauge.nu

const RECORD = 64
const LIFTED = 1
const STALE = 4
const ONCE = 8
const VIEWS = [
    { name: "spawn", x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }
    { name: "turned", x: 29.0, y: 2.5, z: 1.6, yaw: 330, pitch: 0 }
    { name: "yard", x: 40.0, y: 6.0, z: 1.6, yaw: 90, pitch: 10 }
    { name: "window", x: 8.75, y: 17.0, z: 4.6, yaw: 0, pitch: -15 }
    { name: "bay", x: 20.0, y: 17.0, z: 1.6, yaw: 180, pitch: 5 }
    { name: "up", x: 8.75, y: 3.5, z: 1.6, yaw: 90, pitch: 15 }
    { name: "down", x: 1.5, y: 3.5, z: 1.6, yaw: 90, pitch: -15 }
    { name: "garage", x: 16.0, y: 14.0, z: -1.4, yaw: 0, pitch: 0 }
]

def pool-frame [--modes: int = 0, --cold, --slots: int = 0]: nothing -> binary {
    let word = {|v: int| $v | into binary | bytes at 0..<4 }
    [("O" | into binary), 0x[00 00 00], ($modes | into binary | bytes at 0..<1), 0x[00], (if $cold { 0x[01] } else { 0x[00] }), 0x[00], (do $word $slots), (do $word 0), (do $word 0), (do $word 0), (0..<40 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def dump-frame []: nothing -> binary {
    [("D" | into binary), 0x[00 00 00], 0x[ff ff ff ff], (0..<56 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def level-frame [bright: bool, held: bool]: nothing -> binary {
    let flag = {|on: bool| if $on { 0x[01] } else { 0x[00] } }
    [("L" | into binary), 0x[00 00 00], (do $flag $bright), (do $flag $held), 0x[00], 0x[00], (0..<56 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# every dump's tile headers with a signature of their texels
def headers [api: binary, --bare]: nothing -> list<any> {
    let n = (($api | bytes length) // $RECORD)
    mut dumps = []
    mut cur = []
    mut i = 0
    while $i < $n {
        let r = ($api | bytes at ($i * $RECORD)..<(($i + 1) * $RECORD))
        let kind = ($r | bytes at 0..<4 | into int --endian little)
        if $kind == 16 {
            let w = {|o: int| $r | bytes at $o..<($o + 4) | into int --endian little }
            let sig = (if $bare { "" } else {
                let tex = ($api | bytes at (($i + 1) * $RECORD)..<(($i + 343) * $RECORD))
                0..<342 | each {|j| $tex | bytes at ($j * $RECORD + 12)..<($j * $RECORD + 60) } | bytes collect | hash md5
            })
            $cur = ($cur | append { slot: (do $w 4), key: (do $w 8), surface: (do $w 12), level: (do $w 16), frame: (do $w 40), generation: (do $w 44), sig: $sig })
            $i = $i + 343
        } else if $kind == 11 and (($r | bytes at 4..<8 | into int --endian little) == 68) {
            $dumps = ($dumps | append [$cur])
            $cur = []
            $i = $i + 1
        } else {
            $i = $i + 1
        }
    }
    $dumps
}

def main [kernel: path, image: path, disk: path, out: path, mode: string, slots: int = 0] {
    let a = { name: "a", x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }
    let b = { name: "b", x: 29.0, y: 2.5, z: 1.6, yaw: 330, pitch: 0 }
    let at = {|ms: int, bytes: binary| { at: ($ms * 1ms), bytes: $bytes } }
    let place = {|ms: int, p: record| do $at $ms (pose pose-frame $p) }
    let phases = (match $mode {
        "sets" => [
            (do $at 1300 (pool-frame --modes $LIFTED --cold)) (do $place 1500 $a) (do $place 2300 $a) (do $at 2600 (dump-frame))
            (do $at 2800 (pool-frame --modes $LIFTED --cold)) (do $place 2800 $b) (do $place 3600 $b) (do $at 3900 (dump-frame))
        ]
        "lift" => [
            (do $at 1300 (pool-frame --modes $LIFTED --cold --slots $slots)) (do $place 1500 $a) (do $place 2300 $a) (do $at 2600 (dump-frame))
            (do $place 2800 $b) (do $place 3600 $b) (do $at 3900 (dump-frame))
            (do $place 4100 $a) (do $place 4900 $a) (do $at 5200 (dump-frame))
        ]
        "views" => ($VIEWS | enumerate | each {|e|
            let t = 1300 + $e.index * 1300
            [(do $place $t $e.item) (do $at ($t + 200) (pool-frame --modes $LIFTED --cold)) (do $place ($t + 800) $e.item) (do $at ($t + 1100) (dump-frame))]
        } | flatten)
        "budget" => [
            (do $at 1300 (pool-frame --cold --slots $slots)) (do $place 1500 $a) (do $place 2300 $a) (do $at 2600 (dump-frame))
            (do $place 2800 $b) (do $place 3600 $b) (do $at 3900 (dump-frame))
            (do $place 4100 $a) (do $place 4900 $a) (do $at 5200 (dump-frame))
        ]
        _ => (error make { msg: $"no mode ($mode)" })
    })
    let last = ($phases | get at | math max)
    let sends = ($phases | append { at: ($last + 400ms), bytes: (pose command-frame "E") } | sort-by at)
    let run = (jab launch --kernel $kernel --image $image --out ($out | path join $mode) --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --capture ($last + 800ms) --seconds (($last + 3sec) / 1sec | math ceil))
    let api = $run.api
    let m = (gauge measure $api [{ name: "start", places: [], pad: [] }])
    let cold = ((gauge stream $api).configs | last | get from)
    let rows = ($m.rows | where {|r| $r.frame >= $cold } | select -o frame tiles_built evicted slots_used building missed_blocks admitted merged unprocessed tiles_us tile_resets)
    let ds = (if $mode == "views" { headers $api --bare } else { headers $api })
    { mode: $mode, slots: $slots, complete: $m.complete, valid: $m.valid, invalid: ($m.invalid | first 3), qemu: (open --raw $run.qemu_log), rows: $rows, dumps: $ds } | to nuon | save -f ($out | path join $"($mode).nuon")
    print { mode: $mode, complete: $m.complete, valid: $m.valid, dumps: ($ds | each {|d| { tiles: ($d | length), frame: ($d | get -o 0.frame) } }) }
}
