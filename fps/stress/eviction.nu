# The release tier's tile eviction fixtures (TileEviction) on a debug
# image of jab's fps and the still disk, each a launch read from its
# records (gauge measure) and its tile dumps' keys (tiles.nu's `keys`, in
# a nu of its own), asserting as the fps campaign specifies them:
#
# - cycle, EvictionCycle: the ordinary budget, real lumels, the default
#   workers, a cap of CAP slots under the spawn view and the bay
#   alternated, each held to its settle and dumped.
#
# Run as `nu eviction.nu <kernel> <image> <disk> <out> [fixture...]`,
# through `stress.just`'s `eviction image out`; every fixture by default.
use std/assert
use ../../../jab/sdk/nu/jab.nu
use ../../../jab/game/fps/test/pose.nu
use ../../../jab/game/fps/test/gauge.nu

const TILES = (path self | path dirname | path join .. .. .. jab game fps test tiles.nu)

# the cap under which the two views' keys bracket the pool, each within
# it and their union past it
const CAP = 512
const TILE_BYTES = 16384
# a boundary's budget: TILE_ALLOWANCE_US of time, or TILE_QUOTA's 96
# tiles of texels, which a boundary stopped by it has published 96 of
const ALLOWANCE_US = 1000
const QUOTA_TILES = 96
const SPAWN = { name: "spawn", x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }
const BAY = { name: "bay", x: 20.0, y: 17.0, z: 1.6, yaw: 180, pitch: 5 }
# the cycle's timing: the cap and a cold start first, then a leg a view,
# placed at its start, a cold start CYCLE_COLD after on the first two,
# dumped CYCLE_DUMP after, CYCLE_LEG apart
const CYCLE_CAP_AT = 1300
const CYCLE_FIRST = 2600
const CYCLE_LEG = 1300
const CYCLE_COLD = 300
const CYCLE_DUMP = 1100
# pool-holds' settled first sight of the spawn view, its picture's
# reference: the view placed with a cold start at 1500 ms, the
# measurement closed at 4500, the screen at 5000
const SIGHT_AT = 1500ms
const SIGHT_END_AT = 4500ms
const SIGHT_CAPTURE_AT = 5000ms

# The console's O frame, a debug build's (test.nu's pool-frame): byte 4
# the modes, byte 6 a cold start, then words from byte 8: the slots, a
# tier's requests, an open ring's entries, the merge's share, and the
# quota, each 0 for the build's own.
def pool-frame [--modes: int = 0, --cold, --slots: int = 0, --quota: int = 0]: nothing -> binary {
    let word = {|v: int| $v | into binary | bytes at 0..<4 }
    [("O" | into binary), 0x[00 00 00], ($modes | into binary | bytes at 0..<1), 0x[00], (if $cold { 0x[01] } else { 0x[00] }), 0x[00], (do $word $slots), (do $word 0), (do $word 0), (do $word 0), (do $word $quota), (0..<36 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The console's D frame, a debug build's: every surface's READY tiles,
# and with `--building` the tile in construction too.
def dump-frame [--building]: nothing -> binary {
    [("D" | into binary), 0x[00 00 00], 0x[ff ff ff ff], (if $building { 0x[01] } else { 0x[00] }), (0..<55 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# A capture's dumps keyed through tiles.nu in a nu of its own: each
# dump's tiles by their headers and texel hashes, and the problems.
def dump-keys [api: path, out: path]: nothing -> record<dumps: list<any>, problems: list<any>> {
    let r = (^nu $TILES keys $api $out | complete)
    assert equal $r.exit_code 0 $"tiles.nu read the capture's dumps: ($r.stderr | str substring 0..<400)"
    open $out
}

# A frame settled: no block drawn without its tile, no tile in
# construction, nothing admitted, dropped, filtered, or built.
def settled [r: record]: nothing -> bool {
    $r.missed_blocks == 0 and $r.building == 0 and $r.admitted == 0 and $r.dropped == 0 and $r.filtered == 0 and $r.tiles_built == 0
}

# EvictionCycle. The cap and a cold start before any placement, the start
# view's tiles within it; the bay placed with a cold start, dumped at its
# settle, its keys; the spawn placed with a cold start, dumped at its
# settle, its keys and the window's start; then the bay, the spawn, the
# bay, and the spawn, each dumped at its settle; the screen at the last.
# Asserted: the two sets bracket the cap; each later settle's dump holds
# every key of its view and no reset happens in the window; each phase
# builds exactly its renewed keys and evicts exactly those past the free
# slots; slots, generations, and keys dump to dump, and every key's
# texels alike in every dump; the progress rule; the memory; and the
# last spawn's picture pool-holds' settled first sight's. Returns each
# phase's counts and frames and the run's measures.
export def eviction-cycle [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let at = {|ms: int, bytes: binary| { at: ($ms * 1ms), bytes: $bytes } }
    let legs = [
        { name: "bay_sight", view: $BAY, cold: true }
        { name: "spawn_sight", view: $SPAWN, cold: true }
        { name: "bay_return", view: $BAY, cold: false }
        { name: "spawn_return", view: $SPAWN, cold: false }
        { name: "bay_again", view: $BAY, cold: false }
        { name: "spawn_again", view: $SPAWN, cold: false }
    ]
    let timed = ($legs | enumerate | each {|e| $e.item | insert start ($CYCLE_FIRST + $e.index * $CYCLE_LEG) })
    let leg_sends = ($timed | each {|l|
        [(do $at $l.start (pose pose-frame $l.view))]
        | append (if $l.cold { [(do $at ($l.start + $CYCLE_COLD) (pool-frame --cold --slots $CAP))] } else { [] })
        | append [(do $at ($l.start + $CYCLE_DUMP) (dump-frame))]
    } | flatten)
    let last = ($timed | last | get start)
    let end_at = ($last + $CYCLE_DUMP + 300)
    let sends = ([(do $at $CYCLE_CAP_AT (pool-frame --cold --slots $CAP))] ++ $leg_sends ++ [(do $at $end_at (pose command-frame "E"))] | sort-by at)
    let dir = ($out | path join "cycle")
    let run = (jab launch --kernel $kernel --image $image --out $dir --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --capture (($end_at + 400) * 1ms) --seconds ((($end_at + 4000) / 1000) | math ceil))
    assert equal (open --raw $run.qemu_log) "" "QEMU has no complaint about the guest on the eviction cycle"
    assert ($run.screen != "") "the eviction cycle's screen was taken at its last spawn"
    let m = (gauge measure $run.api [{ name: "start", places: [], pad: [] }])
    assert ($m.complete and $m.valid and $m.schema == 5) $"the eviction cycle complete and valid at schema 5: ($m.problems | str join '; ') ($m.invalid | str join '; ')"
    let rows = $m.rows
    let read = (dump-keys ($dir | path join "api.out") ($dir | path join "keys.nuon"))
    assert ($read.problems | is-empty) $"the eviction cycle's dumps read whole: ($read.problems | first 3)"
    assert equal ($read.dumps | length) ($legs | length) $"a dump at every leg's settle: ($read.dumps | length) of ($legs | length)"
    let dumps = ($read.dumps | enumerate | each {|e| { leg: ($legs | get $e.index | get name), view: ($legs | get $e.index | get view.name), frame: ($e.item | get -o 0.frame), tiles: $e.item } })

    # the two sets bracket the cap
    let bay = ($dumps | get 0 | get tiles | get key)
    let spawn = ($dumps | get 1 | get tiles | get key)
    let union = ($bay | append $spawn | uniq | length)
    assert (($bay | length) <= $CAP and ($spawn | length) <= $CAP and $union > $CAP) $"the bay's ($bay | length) keys and the spawn's ($spawn | length) each within the cap of ($CAP) and their union, ($union), past it"
    let keys_of = {|view: string| if $view == "bay" { $bay } else { $spawn } }

    # real eviction, no reset, over the window from the spawn's first settle
    let window_from = ($dumps | get 1 | get frame)
    let window = ($rows | where {|r| $r.frame >= $window_from })
    let resets = ($window | get tile_resets | uniq)
    assert equal ($resets | length) 1 $"no reset in the window from frame ($window_from): tile_resets ($resets)"
    for d in ($dumps | skip 2) {
        let held = ($d.tiles | get key)
        let lost = (do $keys_of $d.view | where {|k| $k not-in $held })
        assert ($lost | is-empty) $"the ($d.leg) settle's dump holds every key of the ($d.view): ($lost | length) missing, ($lost | first 5)"
    }

    # each phase: its accounting, its progress, its frames
    let phases = (2..<($dumps | length) | each {|i|
        let d = ($dumps | get $i)
        let prev = ($dumps | get ($i - 1))
        let own = (do $keys_of $d.view)
        let prev_keys = ($prev.tiles | get key)
        let renewed = ($own | where {|k| $k not-in $prev_keys } | length)
        let free = ($CAP - ($prev.tiles | length))
        let span = ($rows | where {|r| $r.frame > $prev.frame and $r.frame <= $d.frame })
        let built = ($span | get tiles_built | math sum)
        let evicted = ($span | get evicted | math sum)
        assert ($built == $renewed and $evicted == ([($renewed - $free) 0] | math max)) $"the ($d.leg) phase built its ($renewed) renewed keys and evicted those past its ($free) free slots: built ($built), evicted ($evicted)"
        let first_miss = ($span | where {|r| $r.missed_blocks > 0 } | get -o 0.frame)
        assert ($first_miss != null) $"the ($d.leg) phase drew blocks without their tiles: ($span | first 3 | select frame missed_blocks)"
        let merging = ($span | where {|r| $r.frame == ($first_miss + 1) } | get -o 0)
        assert ($merging != null and $merging.merged == $renewed) $"the ($d.leg) phase's boundary after its first miss, frame ($first_miss + 1), merged its ($renewed) renewed keys: ($merging | select -o frame merged unprocessed batch_admitted)"
        let building = ($span | where {|r| $r.tiles_built > 0 })
        let before_last = ($building | drop 1)
        let unspent = ($before_last | where {|r| $r.tiles_us < $ALLOWANCE_US and $r.tiles_built < $QUOTA_TILES })
        assert ($unspent | is-empty) $"every building boundary of the ($d.leg) phase before its last spent its budget, ($ALLOWANCE_US) us or ($QUOTA_TILES) tiles: ($unspent | select frame tiles_built tiles_us | first 3)"
        let last_build = ($building | last | get frame)
        let after = ($span | where {|r| $r.frame == ($last_build + 1) } | get -o 0)
        assert ($after != null and (settled $after)) $"the frame after the ($d.leg) phase's last build, ($last_build + 1), settled: ($after | select -o frame missed_blocks building admitted tiles_built)"
        { leg: $d.leg, renewed: $renewed, free: $free, built: $built, evicted: $evicted, first_miss: $first_miss, settled: ($last_build + 1), frames: ($last_build + 1 - $first_miss), boundaries: ($building | each {|r| $"($r.frame):($r.tiles_built)/($r.evicted)/($r.tiles_us)" } | str join " ") }
    })

    # slots, generations, and keys dump to dump, from the spawn's first settle
    for i in 2..<($dumps | length) {
        let d = ($dumps | get $i)
        let prev = ($dumps | get ($i - 1))
        let pairs = ($prev.tiles | each {|t| let n = ($d.tiles | where slot == $t.slot | get -o 0); if $n == null { null } else { { slot: $t.slot, before: $t, after: $n } } } | compact)
        let kept_wrong = ($pairs | where {|p| $p.before.key == $p.after.key and $p.before.generation != $p.after.generation })
        assert ($kept_wrong | is-empty) $"a slot keeping its key kept its generation into the ($d.leg) dump: ($kept_wrong | first 3 | each {|p| { slot: $p.slot, before: $p.before.generation, after: $p.after.generation } })"
        let stepped_wrong = ($pairs | where {|p| $p.before.key != $p.after.key and $p.after.generation != ($p.before.generation + 1) })
        assert ($stepped_wrong | is-empty) $"a slot taking another key stepped its generation by one into the ($d.leg) dump: ($stepped_wrong | first 3 | each {|p| { slot: $p.slot, before: $p.before.generation, after: $p.after.generation } })"
        let own = (do $keys_of $d.view)
        let moved = ($prev.tiles | where {|t| $t.key in $own } | where {|t| let n = ($d.tiles | where key == $t.key | get -o 0); $n == null or $n.slot != $t.slot or $n.generation != $t.generation })
        assert ($moved | is-empty) $"every ($d.view) key the dump before held kept its slot and generation into the ($d.leg) dump: ($moved | length) moved, ($moved | first 3 | select key slot generation)"
    }
    let hashes = ($dumps | each {|d| $d.tiles | select key texels_sha256 } | flatten | uniq | group-by key | items {|k, v| { key: $k, hashes: ($v | length) } } | where hashes > 1)
    assert ($hashes | is-empty) $"each key's texels the same in every dump that holds it: ($hashes | length) keys differ, ($hashes | first 3)"

    # the memory, from the load on
    let over = ($rows | where {|r| $r.slots_used > $CAP })
    assert ($over | is-empty) $"slots in use at most ($CAP) on every frame: ($over | first 3 | select frame slots_used)"
    let fixed = ($rows | each {|r| $r.memory - $r.tile_bytes } | uniq)
    assert equal ($fixed | length) 1 $"the memory less the tiles' bytes constant, tile_fixed: ($fixed)"
    let bound = (($fixed | first) + $CAP * $TILE_BYTES)
    let past = ($rows | where {|r| $r.memory > $bound or $r.memory_peak > $bound })
    assert ($past | is-empty) $"the memory and its high-water at most tile_fixed plus ($CAP) tiles, ($bound), from the load on: ($past | first 3 | select frame memory memory_peak)"
    let full = ($rows | where {|r| $r.slots_used == $CAP } | get -o 0.frame)
    assert ($full != null) "the pool filled to the cap"
    let peaks = ($rows | where {|r| $r.frame >= $full } | get memory_peak | uniq)
    assert equal ($peaks | length) 1 $"the high-water constant from the first full pool, frame ($full): ($peaks)"

    # the picture: pool-holds' settled first sight of the spawn view
    let sight_dir = ($out | path join "cycle_sight")
    let sight = (jab launch --kernel $kernel --image $image --out $sight_dir --set DEBUG --sound --api --disk $disk --serial "fps" --send ([{ at: $SIGHT_AT, bytes: (pose pose-frame $SPAWN) }, { at: $SIGHT_AT, bytes: (pool-frame --cold) }, { at: $SIGHT_END_AT, bytes: (pose command-frame "E") }]) --capture $SIGHT_CAPTURE_AT --seconds 7)
    assert ($sight.screen != "") "the spawn's settled first sight was captured"
    let same = ((open --raw $run.screen | into binary) == (open --raw $sight.screen | into binary))
    assert $same $"the last spawn's screen identical to its settled first sight: ($run.screen) against ($sight.screen)"

    {
        bay_keys: ($bay | length), spawn_keys: ($spawn | length), union: $union, cap: $CAP,
        phases: $phases, resets: ($resets | first), fixed: ($fixed | first), memory_max: ($rows | get memory | math max),
        peak: ($peaks | first), full_at: $full, dumps: ($dumps | each {|d| { leg: $d.leg, frame: $d.frame, tiles: ($d.tiles | length) } }),
    }
}

def main [kernel: path, image: path, disk: path, out: path, ...fixtures: string] {
    let asked = (if ($fixtures | is-empty) { ["cycle"] } else { $fixtures })
    mkdir $out
    for f in $asked {
        let s = (date now)
        let result = (match $f {
            "cycle" => (eviction-cycle $kernel $image $disk $out)
            _ => (error make { msg: $"no fixture ($f)" })
        })
        let took = (((date now) - $s) / 1sec | math round --precision 1)
        { fixture: $f, seconds: $took, result: $result } | to nuon --indent 1 | save -f ($out | path join $"($f).nuon")
        print $"eviction ($f): ok in ($took) s"
    }
}
