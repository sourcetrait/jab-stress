# The release tier's tile eviction fixtures (TileEviction) on a debug
# image of jab's fps and the still disk, each a launch read from its
# records (gauge measure) and its tile dumps' keys (tiles.nu's `keys`, in
# a nu of its own), asserting as the fps campaign specifies them:
#
# - cycle, EvictionCycle: the ordinary budget, real lumels, the default
#   workers, a cap of CAP slots under the spawn view and the bay
#   alternated, each held to its settle and dumped.
# - rebuild, RebuildBound: the same cycle under the lift with a quota of
#   REBUILD_TILES whole tiles a boundary and the stale mode, so
#   construction is counted work and every phase's rebuild takes exactly
#   its count of boundaries.
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
const TILE_TEXELS = 4096
const TILE_BYTES = 16384
# a boundary's budget: TILE_ALLOWANCE_US of time, or TILE_QUOTA's 96
# tiles of texels, which a boundary stopped by it has published 96 of
const ALLOWANCE_US = 1000
const QUOTA_TILES = 96
# the O frame's modes and the record's kept quota
const LIFTED = 1
const STALE = 4
const QUOTA_KEPT = 16
# RebuildBound's quota, whole tiles a boundary
const REBUILD_TILES = 32
const SPAWN = { name: "spawn", x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }
const BAY = { name: "bay", x: 20.0, y: 17.0, z: 1.6, yaw: 180, pitch: 5 }
# the cycle: the cap and a cold start first, then a leg a view, placed at
# its start, a cold start CYCLE_COLD after on the first two, dumped
# CYCLE_DUMP after, CYCLE_LEG apart
const CYCLE_LEGS = [
    { name: "bay_sight", view: "bay", cold: true }
    { name: "spawn_sight", view: "spawn", cold: true }
    { name: "bay_return", view: "bay", cold: false }
    { name: "spawn_return", view: "spawn", cold: false }
    { name: "bay_again", view: "bay", cold: false }
    { name: "spawn_again", view: "spawn", cold: false }
]
const CYCLE_CAP_AT = 1300
const CYCLE_FIRST = 2600
const CYCLE_LEG = 1300
const CYCLE_COLD = 300
const CYCLE_DUMP = 1100
# pool-holds' settled first sight of the spawn view, the cycle's picture's
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

# One cycle launched under the O frame's modes and quota, every O
# carrying them: the cap and a cold start before any placement, the start
# view's tiles within it; the bay placed with a cold start, dumped at its
# settle; the spawn placed with a cold start, dumped at its settle, the
# window's start; then the bay, the spawn, the bay, and the spawn, each
# dumped at its settle; the screen at the last. The run's records whole
# and valid, its dumps read whole, a dump a leg; returns the run, its
# rows, each dump with its leg and view, and the two views' keys from
# their first sights.
def cycle-launch [kernel: path, image: path, disk: path, out: path, label: string, name: string, modes: int, quota: int]: nothing -> record {
    let at = {|ms: int, bytes: binary| { at: ($ms * 1ms), bytes: $bytes } }
    let views = { spawn: $SPAWN, bay: $BAY }
    let o = {|| pool-frame --modes $modes --cold --slots $CAP --quota $quota }
    let timed = ($CYCLE_LEGS | enumerate | each {|e| $e.item | insert start ($CYCLE_FIRST + $e.index * $CYCLE_LEG) })
    let leg_sends = ($timed | each {|l|
        [(do $at $l.start (pose pose-frame ($views | get $l.view)))]
        | append (if $l.cold { [(do $at ($l.start + $CYCLE_COLD) (do $o))] } else { [] })
        | append [(do $at ($l.start + $CYCLE_DUMP) (dump-frame))]
    } | flatten)
    let end_at = (($timed | last | get start) + $CYCLE_DUMP + 300)
    let sends = ([(do $at $CYCLE_CAP_AT (do $o))] ++ $leg_sends ++ [(do $at $end_at (pose command-frame "E"))] | sort-by at)
    let dir = ($out | path join $name)
    let run = (jab launch --kernel $kernel --image $image --out $dir --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --capture (($end_at + 400) * 1ms) --seconds ((($end_at + 4000) / 1000) | math ceil))
    assert equal (open --raw $run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)"
    assert ($run.screen != "") $"($label)'s screen was taken at its last spawn"
    let m = (gauge measure $run.api [{ name: "start", places: [], pad: [] }])
    assert ($m.complete and $m.valid and $m.schema == 5) $"($label) complete and valid at schema 5: ($m.problems | str join '; ') ($m.invalid | str join '; ')"
    let read = (dump-keys ($dir | path join "api.out") ($dir | path join "keys.nuon"))
    assert ($read.problems | is-empty) $"($label)'s dumps read whole: ($read.problems | first 3)"
    assert equal ($read.dumps | length) ($CYCLE_LEGS | length) $"($label) dumped at every leg's settle: ($read.dumps | length) of ($CYCLE_LEGS | length)"
    let dumps = ($read.dumps | enumerate | each {|e| let l = ($CYCLE_LEGS | get $e.index); { leg: $l.name, view: $l.view, frame: ($e.item | get -o 0.frame), tiles: $e.item } })
    let sets = { bay: ($dumps | get 0 | get tiles | get key), spawn: ($dumps | get 1 | get tiles | get key) }
    { run: $run, rows: $m.rows, dumps: $dumps, sets: $sets }
}

# The two sets bracket the cap: each within it and their union past it.
def assert-bracket [c: record, label: string]: nothing -> int {
    let union = ($c.sets.bay | append $c.sets.spawn | uniq | length)
    assert ((($c.sets.bay | length) <= $CAP) and (($c.sets.spawn | length) <= $CAP) and $union > $CAP) $"($label): the bay's ($c.sets.bay | length) keys and the spawn's ($c.sets.spawn | length) each within the cap of ($CAP) and their union, ($union), past it"
    $union
}

# Real eviction, no reset: each settle's dump after the first sights
# holds every key of its view, and tile_resets stands over the window
# from the spawn's first settle. Returns the resets.
def assert-held [c: record, label: string]: nothing -> int {
    let from = ($c.dumps | get 1 | get frame)
    let resets = ($c.rows | where {|r| $r.frame >= $from } | get tile_resets | uniq)
    assert equal ($resets | length) 1 $"($label): no reset in the window from frame ($from), tile_resets ($resets)"
    for d in ($c.dumps | skip 2) {
        let held = ($d.tiles | get key)
        let lost = ($c.sets | get $d.view | where {|k| $k not-in $held })
        assert ($lost | is-empty) $"($label): the ($d.leg) settle's dump holds every key of the ($d.view), ($lost | length) missing: ($lost | first 5)"
    }
    $resets | first
}

# Each phase after the first sights against the dump before: its renewed
# keys R, its free slots, the rows from that dump to its own, the builds
# and evictions over them, its first miss, and its building boundaries.
def cycle-phases [c: record]: nothing -> list<record> {
    2..<($c.dumps | length) | each {|i|
        let d = ($c.dumps | get $i)
        let prev = ($c.dumps | get ($i - 1))
        let prev_keys = ($prev.tiles | get key)
        let renewed = ($c.sets | get $d.view | where {|k| $k not-in $prev_keys } | length)
        let span = ($c.rows | where {|r| $r.frame > $prev.frame and $r.frame <= $d.frame })
        {
            leg: $d.leg, renewed: $renewed, free: ($CAP - ($prev.tiles | length)), span: $span,
            built: ($span | get tiles_built | math sum), evicted: ($span | get evicted | math sum),
            first_miss: ($span | where {|r| $r.missed_blocks > 0 } | get -o 0.frame),
            building: ($span | where {|r| $r.tiles_built > 0 }),
        }
    }
}

# The accounting: each phase builds exactly its renewed keys and evicts
# exactly those past its free slots; its renewed keys merge at the
# boundary after its first miss; the frame after its last build settles.
def assert-accounting [phases: list<record>, label: string]: nothing -> nothing {
    for p in $phases {
        assert ($p.built == $p.renewed and $p.evicted == ([($p.renewed - $p.free) 0] | math max)) $"($label): the ($p.leg) phase built its ($p.renewed) renewed keys and evicted those past its ($p.free) free slots, built ($p.built), evicted ($p.evicted)"
        assert ($p.first_miss != null) $"($label): the ($p.leg) phase drew blocks without their tiles: ($p.span | first 3 | select frame missed_blocks)"
        let merging = ($p.span | where {|r| $r.frame == ($p.first_miss + 1) } | get -o 0)
        assert ($merging != null and $merging.merged == $p.renewed) $"($label): the ($p.leg) phase's boundary after its first miss, frame ($p.first_miss + 1), merged its ($p.renewed) renewed keys: ($merging | select -o frame merged unprocessed batch_admitted)"
        let last_build = ($p.building | last | get frame)
        let after = ($p.span | where {|r| $r.frame == ($last_build + 1) } | get -o 0)
        assert ($after != null and (settled $after)) $"($label): the frame after the ($p.leg) phase's last build, ($last_build + 1), settled: ($after | select -o frame missed_blocks building admitted tiles_built)"
    }
}

# The tracking, dump to dump from the spawn's first settle: a slot
# keeping its key keeps its generation, a slot taking another key steps
# its generation by exactly one, every key of the returning view the dump
# before held keeps its slot and generation; and every key's texels the
# same in every dump that holds it.
def assert-tracking [c: record, label: string]: nothing -> nothing {
    for i in 2..<($c.dumps | length) {
        let d = ($c.dumps | get $i)
        let prev = ($c.dumps | get ($i - 1))
        let pairs = ($prev.tiles | each {|t| let n = ($d.tiles | where slot == $t.slot | get -o 0); if $n == null { null } else { { slot: $t.slot, before: $t, after: $n } } } | compact)
        let kept_wrong = ($pairs | where {|p| $p.before.key == $p.after.key and $p.before.generation != $p.after.generation })
        assert ($kept_wrong | is-empty) $"($label): a slot keeping its key kept its generation into the ($d.leg) dump: ($kept_wrong | first 3 | each {|p| { slot: $p.slot, before: $p.before.generation, after: $p.after.generation } })"
        let stepped_wrong = ($pairs | where {|p| $p.before.key != $p.after.key and $p.after.generation != ($p.before.generation + 1) })
        assert ($stepped_wrong | is-empty) $"($label): a slot taking another key stepped its generation by one into the ($d.leg) dump: ($stepped_wrong | first 3 | each {|p| { slot: $p.slot, before: $p.before.generation, after: $p.after.generation } })"
        let own = ($c.sets | get $d.view)
        let moved = ($prev.tiles | where {|t| $t.key in $own } | where {|t| let n = ($d.tiles | where key == $t.key | get -o 0); $n == null or $n.slot != $t.slot or $n.generation != $t.generation })
        assert ($moved | is-empty) $"($label): every ($d.view) key the dump before held kept its slot and generation into the ($d.leg) dump, ($moved | length) moved: ($moved | first 3 | select key slot generation)"
    }
    let differing = ($c.dumps | each {|d| $d.tiles | select key texels_sha256 } | flatten | uniq | group-by key | items {|k, v| { key: $k, hashes: ($v | length) } } | where hashes > 1)
    assert ($differing | is-empty) $"($label): each key's texels the same in every dump that holds it, ($differing | length) keys differ: ($differing | first 3)"
}

# EvictionCycle: the cycle under the ordinary budget. The sets bracket
# the cap; real eviction and no reset; the accounting; the tracking; the
# progress rule, every building boundary of a phase before its last
# spending its budget; the memory; and the last spawn's picture
# pool-holds' settled first sight's. Returns each phase's counts and
# frames and the run's measures.
export def eviction-cycle [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let label = "the eviction cycle"
    let c = (cycle-launch $kernel $image $disk $out $label "cycle" 0 0)
    let union = (assert-bracket $c $label)
    let resets = (assert-held $c $label)
    let phases = (cycle-phases $c)
    assert-accounting $phases $label
    for p in $phases {
        let unspent = ($p.building | drop 1 | where {|r| $r.tiles_us < $ALLOWANCE_US and $r.tiles_built < $QUOTA_TILES })
        assert ($unspent | is-empty) $"($label): every building boundary of the ($p.leg) phase before its last spent its budget, ($ALLOWANCE_US) us or ($QUOTA_TILES) tiles: ($unspent | select frame tiles_built tiles_us | first 3)"
    }
    assert-tracking $c $label

    # the memory, from the load on
    let rows = $c.rows
    let over = ($rows | where {|r| $r.slots_used > $CAP })
    assert ($over | is-empty) $"($label): slots in use at most ($CAP) on every frame: ($over | first 3 | select frame slots_used)"
    let fixed = ($rows | each {|r| $r.memory - $r.tile_bytes } | uniq)
    assert equal ($fixed | length) 1 $"($label): the memory less the tiles' bytes constant, tile_fixed: ($fixed)"
    let bound = (($fixed | first) + $CAP * $TILE_BYTES)
    let past = ($rows | where {|r| $r.memory > $bound or $r.memory_peak > $bound })
    assert ($past | is-empty) $"($label): the memory and its high-water at most tile_fixed plus ($CAP) tiles, ($bound), from the load on: ($past | first 3 | select frame memory memory_peak)"
    let full = ($rows | where {|r| $r.slots_used == $CAP } | get -o 0.frame)
    assert ($full != null) $"($label): the pool filled to the cap"
    let peaks = ($rows | where {|r| $r.frame >= $full } | get memory_peak | uniq)
    assert equal ($peaks | length) 1 $"($label): the high-water constant from the first full pool, frame ($full): ($peaks)"

    # the picture: pool-holds' settled first sight of the spawn view
    let sight = (jab launch --kernel $kernel --image $image --out ($out | path join "cycle_sight") --set DEBUG --sound --api --disk $disk --serial "fps" --send ([{ at: $SIGHT_AT, bytes: (pose pose-frame $SPAWN) }, { at: $SIGHT_AT, bytes: (pool-frame --cold) }, { at: $SIGHT_END_AT, bytes: (pose command-frame "E") }]) --capture $SIGHT_CAPTURE_AT --seconds 7)
    assert ($sight.screen != "") $"($label): the spawn's settled first sight was captured"
    let same = ((open --raw $c.run.screen | into binary) == (open --raw $sight.screen | into binary))
    assert $same $"($label): the last spawn's screen identical to its settled first sight, ($c.run.screen) against ($sight.screen)"

    {
        bay_keys: ($c.sets.bay | length), spawn_keys: ($c.sets.spawn | length), union: $union, cap: $CAP, resets: $resets,
        phases: ($phases | each {|p| { leg: $p.leg, renewed: $p.renewed, free: $p.free, built: $p.built, evicted: $p.evicted, first_miss: $p.first_miss, settled: (($p.building | last | get frame) + 1), frames: (($p.building | last | get frame) + 1 - $p.first_miss), boundaries: ($p.building | each {|r| $"($r.frame):($r.tiles_built)/($r.evicted)/($r.tiles_us)" } | str join " ") } }),
        fixed: ($fixed | first), memory_max: ($rows | get memory | math max), peak: ($peaks | first), full_at: $full,
        dumps: ($c.dumps | each {|d| { leg: $d.leg, frame: $d.frame, tiles: ($d.tiles | length) } }),
    }
}

# RebuildBound: the cycle under the lift with a quota of REBUILD_TILES
# whole tiles a boundary and the stale mode, every O carrying them, so
# the record names the kept quota on every frame from the cap on. Every
# phase's R renewed keys merge at the boundary after its first miss and
# complete in exactly ceil(R / REBUILD_TILES) building boundaries, each
# before the last publishing exactly REBUILD_TILES whole tiles and the
# last the rest, BUILDING 0 after every one, the frame after the last
# settled; and with every retirement's entry left naming its slot, the
# cycle's sets, real eviction, accounting, and tracking unchanged.
# Returns each phase's counts and boundaries.
export def rebuild-bound [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let label = "the rebuild bound"
    let modes = ($LIFTED + $STALE)
    let quota = ($REBUILD_TILES * $TILE_TEXELS)
    let c = (cycle-launch $kernel $image $disk $out $label "rebuild" $modes $quota)
    let from = ($c.rows | where {|r| $r.quota == $quota } | get -o 0.frame)
    assert ($from != null) $"($label): the quota of ($quota) texels in force"
    let configured = ($c.rows | where {|r| $r.frame >= $from })
    let unkept = ($configured | where {|r| $r.quota != $quota or $r.config_flags != ($modes + $QUOTA_KEPT) or $r.slots_effective != $CAP })
    assert ($unkept | is-empty) $"($label): every frame from ($from) under the lift, the stale mode, and the kept quota of ($quota) on ($CAP) slots: ($unkept | first 3 | select frame quota config_flags slots_effective)"
    let union = (assert-bracket $c $label)
    let resets = (assert-held $c $label)
    let phases = (cycle-phases $c)
    assert-accounting $phases $label
    for p in $phases {
        let n = (($p.renewed + $REBUILD_TILES - 1) // $REBUILD_TILES)
        let counts = ($p.building | get tiles_built)
        let expected = (0..<$n | each {|i| if $i < ($n - 1) { $REBUILD_TILES } else { $p.renewed - $REBUILD_TILES * ($n - 1) } })
        assert equal $counts $expected $"($label): the ($p.leg) phase's ($p.renewed) keys built in ($n) boundaries, ($REBUILD_TILES) whole tiles each before the last: ($p.building | select frame tiles_built building)"
        let partial = ($p.building | where {|r| $r.building != 0 })
        assert ($partial | is-empty) $"($label): no tile in construction after any of the ($p.leg) phase's building boundaries: ($partial | select frame tiles_built building | first 3)"
    }
    assert-tracking $c $label
    {
        bay_keys: ($c.sets.bay | length), spawn_keys: ($c.sets.spawn | length), union: $union, cap: $CAP, resets: $resets, quota: $quota,
        phases: ($phases | each {|p| { leg: $p.leg, renewed: $p.renewed, free: $p.free, built: $p.built, evicted: $p.evicted, boundaries: ($p.building | length), counts: ($p.building | get tiles_built | str join " ") } }),
    }
}

def main [kernel: path, image: path, disk: path, out: path, ...fixtures: string] {
    let asked = (if ($fixtures | is-empty) { ["cycle" "rebuild"] } else { $fixtures })
    mkdir $out
    for f in $asked {
        let s = (date now)
        let result = (match $f {
            "cycle" => (eviction-cycle $kernel $image $disk $out)
            "rebuild" => (rebuild-bound $kernel $image $disk $out)
            _ => (error make { msg: $"no fixture ($f)" })
        })
        let took = (((date now) - $s) / 1sec | math round --precision 1)
        { fixture: $f, seconds: $took, result: $result } | to nuon --indent 1 | save -f ($out | path join $"($f).nuon")
        print $"eviction ($f): ok in ($took) s"
    }
}
