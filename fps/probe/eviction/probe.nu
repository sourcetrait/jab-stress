# TileEviction's planning probe: the still copy's spawn view (A) and the
# same eye turned about (B), placed in turn under a slot cap, every
# settle dumped (D, every surface), the tiles' keys, slots, generations,
# and texel signatures read back with the pool's counters a frame. Mode
# building dumps the spawn view's settle after a cold start under the
# ordinary budget in pairs, a plain D and one with byte 8 at the same
# moment, read by tiles.nu's keys in a nu of its own.
use ../../../../jab/nu/mod/launch
use ../../../../jab/kit/fierce/test/pose.nu
use ../../../../jab/kit/fierce/test/gauge.nu

const TILES = (path self | path dirname | path join .. .. .. .. jab kit fierce test tiles.nu)
const RECORD = 64
# the quota mode's: 32 whole tiles a boundary, and 32 tiles and 8 rows
const QUOTA_WHOLE = (32 * 4096)
const QUOTA_PARTIAL = (32 * 4096 + 8 * 64)
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

def pool-frame [--modes: int = 0, --cold, --slots: int = 0, --quota: int = 0]: nothing -> binary {
    let word = {|v: int| $v | into binary | bytes at 0..<4 }
    [("O" | into binary), 0x[00 00 00], ($modes | into binary | bytes at 0..<1), 0x[00], (if $cold { 0x[01] } else { 0x[00] }), 0x[00], (do $word $slots), (do $word 0), (do $word 0), (do $word 0), (do $word $quota), (0..<36 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def dump-frame [--building]: nothing -> binary {
    [("D" | into binary), 0x[00 00 00], 0x[ff ff ff ff], (if $building { 0x[01] } else { 0x[00] }), (0..<55 | each {|i| 0x[00] } | bytes collect)] | bytes collect
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

def main [kernel: path, image: path, disk: path, out: path, mode: string, slots: int = 0, --view: string = "bay", --cycles: int = 2, --modes: int = 0, --tag: string = ""] {
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
        "pair" => {
            let b2 = ($VIEWS | where name == $view | first)
            let cold = [(do $at 1300 (pool-frame --modes $modes --cold --slots $slots))]
            let legs = (0..<(2 * $cycles + 1) | each {|i|
                let t = 1500 + $i * 1300
                let p = (if ($i mod 2) == 0 { $a } else { $b2 })
                [(do $place $t $p) (do $place ($t + 800) $p) (do $at ($t + 1100) (dump-frame))]
            } | flatten)
            $cold | append $legs
        }
        "budget" => [
            (do $at 1300 (pool-frame --cold --slots $slots)) (do $place 1500 $a) (do $place 2300 $a) (do $at 2600 (dump-frame))
            (do $place 2800 $b) (do $place 3600 $b) (do $at 3900 (dump-frame))
            (do $place 4100 $a) (do $place 4900 $a) (do $at 5200 (dump-frame))
        ]
        "building" => {
            # the spawn's view is A from the start, so its settle follows the
            # cold start, about 17 ms a frame
            let start = [(do $place 1100 $a) (do $at 1300 (pool-frame --cold --slots $slots))]
            let pairs = (1..20 | each {|i| let t = 1300 + $i * 5; [(do $at $t (dump-frame)) (do $at $t (dump-frame --building))] } | flatten)
            $start | append $pairs
        }
        # whole tiles to the settle; then one construction a phase under
        # ONCE, held for its dump: 32 tiles and 8 rows from a cold start,
        # 32 tiles from that partial, 32 tiles and 8 rows from the next
        "quota" => [
            (do $place 1100 $a)
            (do $at 1300 (pool-frame --modes $LIFTED --cold --quota $QUOTA_WHOLE))
            (do $at 2300 (pool-frame --modes ($LIFTED + $ONCE) --cold --quota $QUOTA_PARTIAL))
            (do $at 2800 (dump-frame --building))
            (do $at 3300 (pool-frame --modes ($LIFTED + $ONCE) --quota $QUOTA_WHOLE))
            (do $at 3800 (dump-frame --building))
            (do $at 4300 (pool-frame --modes ($LIFTED + $ONCE) --quota $QUOTA_PARTIAL))
            (do $at 4800 (dump-frame --building))
        ]
        _ => (error make { msg: $"no mode ($mode)" })
    })
    let last = ($phases | get at | math max)
    let sends = ($phases | append { at: ($last + 400ms), bytes: (pose command-frame "E") } | sort-by at)
    let name = (if $tag == "" { $mode } else { $"($mode)_($tag)" })
    let run = (launch --kernel $kernel --image $image --out ($out | path join $name) --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --capture ($last + 800ms) --seconds (($last + 3sec) / 1sec | math ceil))
    let api = $run.api
    let m = (gauge measure $api [{ name: "start", places: [], pad: [] }])
    let cold = ((gauge stream $api).configs | last | get from)
    let rows = ($m.rows | where {|r| $r.frame >= $cold } | select -o frame tiles_built evicted slots_used slots_effective building missed_blocks admitted merged unprocessed tiles_us tile_resets tile_bytes tile_peak memory memory_peak)
    if $mode == "quota" {
        let keys = ($out | path join $"($name)_keys.nuon")
        let k = (^nu $TILES keys ($out | path join $name "api.out") $keys | complete)
        if $k.exit_code != 0 { error make { msg: $"tiles.nu keys: ($k.stderr)" } }
        let read = (open $keys)
        let configs = ((gauge stream $api).configs | select from quota config_flags)
        let phased = ($m.rows | where {|r| $r.quota == $QUOTA_WHOLE or $r.quota == $QUOTA_PARTIAL } | select -o frame tiles_built building quota config_flags)
        let builds = ($phased | where {|r| $r.tiles_built > 0 })
        let held = ($phased | where {|r| $r.tiles_built == 0 } | each {|r| $"quota ($r.quota) flags ($r.config_flags) building ($r.building)" } | uniq --count)
        let dumps = ($read.dumps | each {|d| { frame: ($d | get -o 0.frame), ready: ($d | where state == 2 | length), building: ($d | where state == 1 | select -o slot key row) } })
        let summary = { complete: $m.complete, valid: $m.valid, problems: ($read.problems | length), configs: $configs, builds: $builds, held: $held, dumps: $dumps }
        $summary | to nuon | save -f ($out | path join $"($name).nuon")
        print ($summary | to nuon)
        return
    }
    if $mode == "building" {
        let keys = ($out | path join $"($name)_keys.nuon")
        let k = (^nu $TILES keys ($out | path join $name "api.out") $keys | complete)
        if $k.exit_code != 0 { error make { msg: $"tiles.nu keys: ($k.stderr)" } }
        let read = (open $keys)
        # the dumps alternate plain and asked, in the order sent; a pair sent
        # at one moment can still fall to two frames
        let ds = ($read.dumps | enumerate | each {|e| { dump: $e.index, asked: (($e.index mod 2) == 1), frame: ($e.item | get -o 0.frame), tiles: ($e.item | length), building: ($e.item | where state == 1 | select slot key level row generation) } })
        let pairs = ($ds | where asked | each {|d|
            let p = ($read.dumps | get ($d.dump - 1))
            let a = ($read.dumps | get $d.dump)
            let same = (($p | is-not-empty) and ($a | is-not-empty) and (($p | first | get frame) == ($a | first | get frame)))
            { dump: $d.dump, frame: $d.frame, same_frame: $same, ready_equal: (($a | where state == 2) == $p), building: $d.building }
        })
        let summary = { problems: ($read.problems | length), dumps: ($ds | length), plain_building: ($ds | where not asked | each {|d| $d.building | length } | math sum), asked_building: ($pairs | where {|p| $p.building | is-not-empty } | length), same_frame: ($pairs | where same_frame | length), same_frame_ready_equal: ($pairs | where same_frame | where ready_equal | length), building: ($pairs | where {|p| $p.same_frame and ($p.building | is-not-empty) } | each {|p| { frame: $p.frame, slot: ($p.building | first | get slot), row: ($p.building | first | get row), tiles: (($ds | get $p.dump).tiles) } } | uniq) }
        { mode: $mode, complete: $m.complete, valid: $m.valid, problems: $read.problems, summary: $summary, dumps: ($ds | reject building), pairs: $pairs, rows: $rows } | to nuon | save -f ($out | path join $"($name).nuon")
        print ($summary | to nuon)
        return
    }
    let ds = (if $mode == "views" { headers $api --bare } else { headers $api })
    { mode: $mode, slots: $slots, view: $view, modes: $modes, complete: $m.complete, valid: $m.valid, invalid: ($m.invalid | first 3), qemu: (open --raw $run.qemu_log), rows: $rows, dumps: $ds } | to nuon | save -f ($out | path join $"($name).nuon")
    print { mode: $mode, complete: $m.complete, valid: $m.valid, dumps: ($ds | each {|d| { tiles: ($d | length), frame: ($d | get -o 0.frame) } }) }
}
