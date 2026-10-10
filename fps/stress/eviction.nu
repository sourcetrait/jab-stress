# The release tier's tile eviction fixtures (TileEviction) on a debug
# image of jab's fps and the still disk, each a launch read from its
# records (gauge measure) and its tile dumps' keys (tiles.nu's `keys`, in
# a nu of its own), asserting as the fps campaign specifies them:
#
# - cycle, EvictionCycle: the ordinary budget, real lumels, the default
#   workers, a cap of CAP slots under the spawn view and the bay
#   alternated, each held to its settle and dumped; the last spawn's
#   picture and its reference's each bound by its stamp to a validated,
#   settled frame (picture-refusals), and the two equal outside the
#   stamp; then each picture's evidence altered one way at a time and
#   refused for exactly that (picture-negatives, PictureNegatives).
# - rebuild, RebuildBound: the same cycle under the lift with a quota of
#   REBUILD_TILES whole tiles a boundary and the stale mode, so
#   construction is counted work and every phase's rebuild publishes at
#   exactly its frames.
# - held, HeldPartial: the spawn's construction held partial by the lift,
#   a quota, and ONCE through the screen and E, its picture refused as
#   unsettled and for nothing else.
#
# Run as `nu eviction.nu <kernel> <image> <disk> <out> [fixture...]`,
# through `stress.just`'s `eviction image out`; every fixture by default.
use std/assert
use ../../../jab/sdk/nu/jab.nu
use ../../../jab/game/fps/test/pose.nu
use ../../../jab/game/fps/test/gauge.nu
use ../../../jab/game/fps/test/test.nu [stamp-of ppm-head record-altered raise-frame rows-differ STAMP_BITS STAMP_CELL STAMP_ONE STAMP_ZERO STORAGE_KIND STORAGE_BUILDING]

const TILES = (path self | path dirname | path join .. .. .. jab game fps test tiles.nu)

# the cap under which the two views' keys bracket the pool, each within
# it and their union past it
const CAP = 512
const TILE_TEXELS = 4096
const TILE_ROW_TEXELS = 64
const TILE_BYTES = 16384
# the API's records, the end marker's kind (gauge.nu's KIND_END), and a
# dump header's state of a tile in construction
const RECORD = 64
const KIND_END = 9
const DUMP_BUILDING = 1
# a boundary's budget: TILE_ALLOWANCE_US of time, or TILE_QUOTA's 96
# tiles of texels, which a boundary stopped by it has published 96 of
const ALLOWANCE_US = 1000
const QUOTA_TILES = 96
# the O frame's modes and the record's kept quota
const LIFTED = 1
const STALE = 4
const ONCE = 8
const QUOTA_KEPT = 16
# RebuildBound's quota, whole tiles a boundary
const REBUILD_TILES = 32
const SPAWN = { name: "spawn", x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }
const BAY = { name: "bay", x: 20.0, y: 17.0, z: 1.6, yaw: 180, pitch: 5 }
# the HUD's stamp from the start of every launch (raise-frame's M, before
# anything else is sent): a frame's number modulo STAMP_SPAN on its screen
const STAMP_AT = 1200
const STAMP_SPAN = (1 bit-shl $STAMP_BITS)
# every launch measured as one leg from the start
const LEGS = [{ name: "start", places: [], pad: [] }]
# the cycle: the cap and a cold start first, then a leg a view, placed at
# its start, a cold start CYCLE_COLD after on the first two, dumped
# CYCLE_DUMP after, CYCLE_LEG apart; the screen CYCLE_SCREEN after the
# last leg's dump while the run goes on, and E CYCLE_END after the dump,
# after the screen
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
const CYCLE_SCREEN = 150
const CYCLE_END = 300
# pool-holds' settled first sight of the spawn view, the cycle's picture's
# reference: the view placed with a cold start at 1500 ms, the screen at
# 4000 while the run goes on, and E at 4500, after it
const SIGHT_AT = 1500ms
const SIGHT_SCREEN_AT = 4000ms
const SIGHT_END_AT = 4500ms
const SIGHT_SECONDS = 9
# HeldPartial: the spawn placed at HELD_AT; HELD_ONCE_AFTER later, never
# with it, an O with the lift, ONCE, a cold start, and a quota of
# HELD_TILES tiles and HELD_ROWS rows; the screen at HELD_SCREEN_AT while
# the run goes on, D with byte 8 at HELD_DUMP_AT and E at HELD_END_AT,
# both after it
const HELD_AT = 1500
const HELD_ONCE_AFTER = 300
const HELD_SCREEN_AT = 3000
const HELD_DUMP_AT = 3200
const HELD_END_AT = 3400
const HELD_SECONDS = 8
const HELD_TILES = 32
const HELD_ROWS = 8

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

# A frame's settling fields that are not zero, named with the frame.
def unsettled-fields [r: record]: nothing -> string {
    let broken = ([missed_blocks building admitted dropped filtered tiles_built] | where {|f| ($r | get $f) != 0 })
    $"frame ($r.frame): ($broken | each {|f| $'($f) ($r | get $f)' } | str join ', ')"
}

# A launch's screen held whole, or null when it took none.
def capture-of [screen: string]: nothing -> oneof<binary, nothing> {
    if $screen == "" { null } else { open --raw $screen | into binary }
}

# A capture with its stamp's cells written as hud.S writes a frame's:
# the low STAMP_BITS bits of `value`, a cell of STAMP_CELL pixels square a
# bit along the top-left, the n-th from the left the n-th bit, STAMP_ONE a
# one and STAMP_ZERO a zero.
export def stamp-written [bytes: binary, value: int]: nothing -> binary {
    let head = (ppm-head $bytes)
    let width = ($bytes | bytes at 0..<$head | decode | lines | get 1 | split row " " | first | into int)
    let row = (0..<$STAMP_BITS | each {|bit|
        let colour = (if ((($value bit-shr $bit) bit-and 1) == 1) { $STAMP_ONE } else { $STAMP_ZERO })
        0..<$STAMP_CELL | each {|_| $colour }
    } | flatten | bytes collect)
    let span = ($row | bytes length)
    mut out = $bytes
    for y in 0..<$STAMP_CELL {
        let o = ($head + ($y * $width * 3))
        $out = ([($out | bytes at 0..<$o) $row ($out | bytes at ($o + $span)..)] | bytes collect)
    }
    $out
}

# The window a picture's stamp must name a frame of, read from a complete
# measurement: from the frame after the last that published at `from` or
# later, before the end marker's.
def picture-window [m: record, from: int]: nothing -> record<last_build: int, final: int> {
    let published = ($m.rows | where {|r| $r.frame >= $from and $r.frame < $m.final and $r.tiles_built > 0 } | get frame)
    { last_build: (if ($published | is-empty) { $from - 1 } else { $published | last }), final: $m.final }
}

# The frame of the window whose number the stamp holds, null when none.
def displayed-frame [m: record, window: record, stamp: int]: nothing -> oneof<int, nothing> {
    $m.rows | where {|r| $r.frame > $window.last_build and $r.frame < $window.final and ($r.frame mod $STAMP_SPAN) == $stamp } | get -o 0.frame
}

# A picture's refusals, each a kind, its detail, and the frames it
# names, in prerequisite order, a refusal ending the checks that need what
# it refuses. `e` is a launch's evidence: its `measure`, its `capture`
# (null when it took none), `from` (the phase's first frame), and the
# screen's `completed` and E's `ended`, seconds from the start (null when
# unrecorded). The measurement incomplete, else invalid; the capture
# absent, else its stamp unreadable; with both usable, the stamp naming no
# frame f with last_build + 1 <= f < final (picture-window), else each
# frame from last_build + 1 through the displayed one unsettled; and
# whatever those hold, the screen's completion or E's write unrecorded,
# else E written at or before the screen completed. Empty when the
# picture is bound.
export def picture-refusals [e: record]: nothing -> list<record<kind: string, detail: string, frames: list<int>>> {
    let m = $e.measure
    let measured = (if not $m.complete {
        [{ kind: "incomplete", detail: ($m.problems | first 3 | str join "; "), frames: [] }]
    } else if not $m.valid {
        [{ kind: "invalid", detail: ($m.invalid | first 3 | str join "; "), frames: [] }]
    } else { [] })
    let stamp = (if $e.capture == null { null } else { try { stamp-of $e.capture } catch { null } })
    let read = (if $e.capture == null {
        [{ kind: "no capture", detail: "the launch took no screen", frames: [] }]
    } else if $stamp == null {
        [{ kind: "no stamp", detail: "a cell of the stamp is neither STAMP_ONE nor STAMP_ZERO throughout", frames: [] }]
    } else { [] })
    let framed = (if ($measured | is-not-empty) or ($read | is-not-empty) { [] } else {
        let window = (picture-window $m $e.from)
        let shown = (displayed-frame $m $window $stamp)
        if $shown == null {
            [{ kind: "outside the window", detail: $"the stamp ($stamp) names no frame from ($window.last_build + 1) before the end marker's, ($window.final)", frames: [] }]
        } else {
            let unsettled = ($m.rows | where {|r| $r.frame > $window.last_build and $r.frame <= $shown } | where {|r| not (settled $r) })
            if ($unsettled | is-empty) { [] } else {
                [{ kind: "unsettled", detail: ($unsettled | first 3 | each {|r| unsettled-fields $r } | str join "; "), frames: ($unsettled | get frame) }]
            }
        }
    })
    mut timed = []
    if $e.completed == null {
        $timed = ($timed | append { kind: "no screen time", detail: "the screen's completion unrecorded", frames: [] })
    }
    if $e.ended == null {
        $timed = ($timed | append { kind: "no E time", detail: "E's write unrecorded", frames: [] })
    }
    if $e.completed != null and $e.ended != null {
        if $e.ended <= $e.completed {
            $timed = ($timed | append { kind: "E not after", detail: $"E written at ($e.ended) s, the screen completed at ($e.completed) s", frames: [] })
        }
    }
    $measured ++ $read ++ $framed ++ $timed
}

# A capture with one pixel's three bytes written.
def pixel-written [bytes: binary, at: list<int>, colour: binary]: nothing -> binary {
    let head = (ppm-head $bytes)
    let width = ($bytes | bytes at 0..<$head | decode | lines | get 1 | split row " " | first | into int)
    let o = ($head + ((($at.1 * $width) + $at.0) * 3))
    [($bytes | bytes at 0..<$o) $colour ($bytes | bytes at ($o + 3)..)] | bytes collect
}

# The binding's negatives on a launch's evidence, which carries its
# records (`api`) and `legs` besides what picture-refusals reads: the
# evidence as taken, the control, refused for nothing; then each
# alteration alone refused for exactly its kind. A stamp cell's pixel
# neither colour; the capture absent; the capture re-stamped last_build,
# then final, the window's two edges, each read back by stamp-of; E
# written before the screen's completion, then at it; the completion
# absent; E's write absent; the displayed frame's storage record given
# BUILDING 1, re-measured complete and valid, refused at that frame
# alone; the records cut at the end marker; a storage record's BUILDING
# past its slots in use, re-measured complete and invalid. Returns each
# case and its kinds.
export def picture-negatives [e: record]: nothing -> list<record<case: string, kinds: list<string>>> {
    let control = (picture-refusals $e)
    assert ($control | is-empty) $"($e.label)'s evidence, the control, refused for nothing: ($control | each {|r| $'($r.kind): ($r.detail)' } | str join '; ')"
    let window = (picture-window $e.measure $e.from)
    let displayed = (displayed-frame $e.measure $window (stamp-of $e.capture))
    let shown = ($e.measure.rows | where frame == $displayed | get 0)
    let restamped = {|v: int|
        let c = (stamp-written $e.capture $v)
        assert equal (stamp-of $c) ($v mod $STAMP_SPAN) $"($e.label)'s capture re-stamped ($v) reads back"
        $c
    }
    let building_one = (gauge measure (record-altered $e.api $STORAGE_KIND $displayed $STORAGE_BUILDING 1) $e.legs)
    assert ($building_one.complete and $building_one.valid) $"($e.label)'s records with BUILDING 1 at the displayed frame ($displayed) complete and valid: ($building_one.problems | str join '; ') ($building_one.invalid | str join '; ')"
    let overfull = (gauge measure (record-altered $e.api $STORAGE_KIND $displayed $STORAGE_BUILDING ($shown.slots_used + 1)) $e.legs)
    assert ($overfull.complete and not $overfull.valid) $"($e.label)'s records with BUILDING past the slots in use at frame ($displayed) complete and invalid: ($overfull.problems | str join '; ')"
    # the run goes on past E, so its records cut at the end marker's, the
    # first record of its kind
    let marker = ($e.api | bytes index-of --all ($KIND_END | into binary | bytes at 0..<4) | where {|o| ($o mod $RECORD) == 0 } | first)
    let cut = (gauge measure ($e.api | bytes at 0..<$marker) $e.legs)
    let cases = [
        { case: "a stamp cell's pixel neither colour", e: ($e | upsert capture (pixel-written $e.capture [0 0] 0x[80 80 80])), kinds: ["no stamp"] }
        { case: "the capture absent", e: ($e | upsert capture null), kinds: ["no capture"] }
        { case: $"re-stamped last_build, ($window.last_build)", e: ($e | upsert capture (do $restamped $window.last_build)), kinds: ["outside the window"] }
        { case: $"re-stamped final, ($window.final)", e: ($e | upsert capture (do $restamped $window.final)), kinds: ["outside the window"] }
        { case: "E before the screen's completion", e: ($e | upsert ended ($e.completed - 0.1)), kinds: ["E not after"] }
        { case: "E at the screen's completion", e: ($e | upsert ended $e.completed), kinds: ["E not after"] }
        { case: "the screen's completion absent", e: ($e | upsert completed null), kinds: ["no screen time"] }
        { case: "E's write absent", e: ($e | upsert ended null), kinds: ["no E time"] }
        { case: $"BUILDING 1 at the displayed frame, ($displayed)", e: ($e | upsert measure $building_one), kinds: ["unsettled"] }
        { case: "the records cut at the end marker", e: ($e | upsert measure $cut), kinds: ["incomplete"] }
        { case: $"BUILDING past the slots in use at frame ($displayed)", e: ($e | upsert measure $overfull), kinds: ["invalid"] }
    ]
    # loops, so a failing assertion is the error raised, not an each's
    mut read = []
    for c in $cases {
        let refused = (picture-refusals $c.e)
        assert (($refused | get kind) == $c.kinds) $"($e.label), ($c.case): refused as ($c.kinds | str join ', '), refused as ($refused | each {|r| $'($r.kind): ($r.detail)' } | str join '; ')"
        if $c.kinds == ["unsettled"] {
            assert equal ($refused | get 0.frames) [$displayed] $"($e.label), ($c.case): refused at that frame alone"
        }
        $read = ($read | append { case: $c.case, kinds: ($refused | get kind) })
    }
    $read
}

# One cycle launched under the O frame's modes and quota, every O
# carrying them: the HUD's stamp first; the cap and a cold start before
# any placement, the start view's tiles within it; the bay placed with a
# cold start, dumped at its settle; the spawn placed with a cold start,
# dumped at its settle, the window's start; then the bay, the spawn, the
# bay, and the spawn, each dumped at its settle; the screen after the
# last dump while the run goes on, and E after it. The run's records
# whole and valid, its dumps read whole, a dump a leg; returns the run,
# its measurement and rows, each dump with its leg and view, the two
# views' keys from their first sights, and E's write.
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
    let dump_at = (($timed | last | get start) + $CYCLE_DUMP)
    let end_at = ($dump_at + $CYCLE_END)
    let ended = (do $at $end_at (pose command-frame "E"))
    let sends = ([(do $at $STAMP_AT (raise-frame 0 --stamp)) (do $at $CYCLE_CAP_AT (do $o))] ++ $leg_sends ++ [$ended] | sort-by at)
    let dir = ($out | path join $name)
    let run = (jab launch --kernel $kernel --image $image --out $dir --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --screen (($dump_at + $CYCLE_SCREEN) * 1ms) --seconds ((($end_at + 4000) / 1000) | math ceil))
    assert equal (open --raw $run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)"
    assert ($run.screen != "") $"($label)'s screen was taken at its last spawn"
    let m = (gauge measure $run.api $LEGS)
    assert ($m.complete and $m.valid and $m.schema == 5) $"($label) complete and valid at schema 5: ($m.problems | str join '; ') ($m.invalid | str join '; ')"
    let read = (dump-keys ($dir | path join "api.out") ($dir | path join "keys.nuon"))
    assert ($read.problems | is-empty) $"($label)'s dumps read whole: ($read.problems | first 3)"
    assert equal ($read.dumps | length) ($CYCLE_LEGS | length) $"($label) dumped at every leg's settle: ($read.dumps | length) of ($CYCLE_LEGS | length)"
    let dumps = ($read.dumps | enumerate | each {|e| let l = ($CYCLE_LEGS | get $e.index); { leg: $l.name, view: $l.view, frame: ($e.item | get -o 0.frame), tiles: $e.item } })
    let sets = { bay: ($dumps | get 0 | get tiles | get key), spawn: ($dumps | get 1 | get tiles | get key) }
    let e_index = ($sends | enumerate | where {|x| $x.item.at == $ended.at and $x.item.bytes == $ended.bytes } | get 0.index)
    { run: $run, measure: $m, rows: $m.rows, dumps: $dumps, sets: $sets, ended: ($run.send_seconds | get $e_index) }
}

# pool-holds' settled first sight of the spawn view, the cycle's
# picture's reference, stamped from the start: the view placed with a
# cold start at SIGHT_AT, the screen at SIGHT_SCREEN_AT while the run
# goes on, E at SIGHT_END_AT after it. Returns its picture's evidence,
# its window the whole run's, with its records and legs.
def sight-launch [kernel: path, image: path, disk: path, out: path, label: string]: nothing -> record {
    let ended = { at: $SIGHT_END_AT, bytes: (pose command-frame "E") }
    let sends = [
        { at: ($STAMP_AT * 1ms), bytes: (raise-frame 0 --stamp) }
        { at: $SIGHT_AT, bytes: (pose pose-frame $SPAWN) }
        { at: $SIGHT_AT, bytes: (pool-frame --cold) }
        $ended
    ]
    let run = (jab launch --kernel $kernel --image $image --out $out --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --screen $SIGHT_SCREEN_AT --seconds $SIGHT_SECONDS)
    assert equal (open --raw $run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)"
    let m = (gauge measure $run.api $LEGS)
    let e_index = ($sends | enumerate | where {|x| $x.item.at == $ended.at and $x.item.bytes == $ended.bytes } | get 0.index)
    { label: $label, measure: $m, api: $run.api, legs: $LEGS, capture: (capture-of $run.screen), from: 0, completed: $run.screen_completed, ended: ($run.send_seconds | get $e_index) }
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

# Each phase after the first sights, from the frame after the dump before
# to its own dump's: its renewed keys R, its free slots, its rows, the
# builds and evictions over them, its first miss, the frames that
# published, and the last of them.
def cycle-phases [c: record]: nothing -> list<record> {
    2..<($c.dumps | length) | each {|i|
        let d = ($c.dumps | get $i)
        let prev = ($c.dumps | get ($i - 1))
        let prev_keys = ($prev.tiles | get key)
        let renewed = ($c.sets | get $d.view | where {|k| $k not-in $prev_keys } | length)
        let span = ($c.rows | where {|r| $r.frame > $prev.frame and $r.frame <= $d.frame })
        let published = ($span | where {|r| $r.tiles_built > 0 } | get frame)
        {
            leg: $d.leg, view: $d.view, start: ($prev.frame + 1), dump: $d.frame,
            renewed: $renewed, free: ($CAP - ($prev.tiles | length)), span: $span,
            built: ($span | get tiles_built | math sum), evicted: ($span | get evicted | math sum),
            first_miss: ($span | where {|r| $r.missed_blocks > 0 } | get -o 0.frame),
            published: $published, last_build: (if ($published | is-empty) { null } else { $published | last }),
        }
    }
}

# The accounting: each phase builds exactly its renewed keys and evicts
# exactly those past its free slots; its renewed keys merge at the
# boundary after its first miss; every frame from the one after its last
# build through its dump settled.
def assert-accounting [phases: list<record>, label: string]: nothing -> nothing {
    for p in $phases {
        assert ($p.built == $p.renewed and $p.evicted == ([($p.renewed - $p.free) 0] | math max)) $"($label): the ($p.leg) phase built its ($p.renewed) renewed keys and evicted those past its ($p.free) free slots, built ($p.built), evicted ($p.evicted)"
        assert ($p.first_miss != null) $"($label): the ($p.leg) phase drew blocks without their tiles: ($p.span | first 3 | select frame missed_blocks)"
        let merging = ($p.span | where {|r| $r.frame == ($p.first_miss + 1) } | get -o 0)
        assert ($merging != null and $merging.merged == $p.renewed) $"($label): the ($p.leg) phase's boundary after its first miss, frame ($p.first_miss + 1), merged its ($p.renewed) renewed keys: ($merging | select -o frame merged unprocessed batch_admitted)"
        assert ($p.last_build != null) $"($label): the ($p.leg) phase published"
        let after = ($p.span | where {|r| $r.frame > $p.last_build })
        let unsettled = ($after | where {|r| not (settled $r) })
        assert ((($after | length) == ($p.dump - $p.last_build)) and ($unsettled | is-empty)) $"($label): every frame of the ($p.leg) phase from the one after its last build, ($p.last_build + 1), through its dump, ($p.dump), settled: ($unsettled | first 3 | each {|r| unsettled-fields $r } | str join '; ')"
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
# progress rule, every boundary of a phase from the one after its first
# miss to its last build's, that one exempt, spending its budget, one
# that published nothing among them; the memory; and the last spawn's
# picture and its reference, pool-holds' settled first sight, each bound
# to a validated, settled frame and equal outside the stamp, then each
# one's negatives. Returns each phase's counts and frames, the run's
# measures, the pictures' frames, and the negatives' kinds.
export def eviction-cycle [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let label = "the eviction cycle"
    let c = (cycle-launch $kernel $image $disk $out $label "cycle" 0 0)
    let union = (assert-bracket $c $label)
    let resets = (assert-held $c $label)
    let phases = (cycle-phases $c)
    assert-accounting $phases $label
    for p in $phases {
        let interval = ($p.span | where {|r| $r.frame > $p.first_miss and $r.frame < $p.last_build })
        let unspent = ($interval | where {|r| $r.tiles_us < $ALLOWANCE_US and $r.tiles_built < $QUOTA_TILES })
        assert ((($interval | length) == ([($p.last_build - $p.first_miss - 1) 0] | math max)) and ($unspent | is-empty)) $"($label): every boundary of the ($p.leg) phase from the one after its first miss, ($p.first_miss + 1), before its last build's, ($p.last_build), spent its budget, ($ALLOWANCE_US) us or ($QUOTA_TILES) tiles: ($unspent | select frame tiles_built tiles_us building | first 3)"
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

    # the pictures: the last spawn's, bound to a frame of the final spawn
    # phase from its last build, and its reference's, each refused for
    # nothing; then the two equal outside the stamp's cells
    let spawn = ($phases | last)
    assert equal $spawn.view "spawn" $"($label): the final phase the spawn's"
    let pictures = [
        { label: $label, measure: $c.measure, api: $c.run.api, legs: $LEGS, capture: (capture-of $c.run.screen), from: $spawn.start, completed: $c.run.screen_completed, ended: $c.ended }
        (sight-launch $kernel $image $disk ($out | path join "cycle_sight") $"($label)'s reference, the spawn's settled first sight")
    ]
    for e in $pictures {
        let refused = (picture-refusals $e)
        assert ($refused | is-empty) $"($e.label)'s picture bound to a validated, settled frame: ($refused | each {|r| $'($r.kind): ($r.detail)' } | str join '; ')"
    }
    let a = (stamp-written ($pictures | get 0 | get capture) 0)
    let b = (stamp-written ($pictures | get 1 | get capture) 0)
    if $a != $b {
        let rows_apart = (rows-differ $a $b [0 0 1920 1080])
        assert false $"($label): the last spawn's screen identical to its settled first sight outside the stamp's cells, ($rows_apart | length) rows differing from row ($rows_apart | get -o 0)"
    }
    let framed = ($pictures | each {|e|
        let window = (picture-window $e.measure $e.from)
        let stamp = (stamp-of $e.capture)
        { label: $e.label, last_build: $window.last_build, displayed: (displayed-frame $e.measure $window $stamp), final: $window.final, completed: $e.completed, ended: $e.ended }
    })
    # each picture's evidence altered one way at a time (PictureNegatives)
    mut negatives = []
    for e in $pictures {
        $negatives = ($negatives | append { label: $e.label, cases: (picture-negatives $e) })
    }

    {
        bay_keys: ($c.sets.bay | length), spawn_keys: ($c.sets.spawn | length), union: $union, cap: $CAP, resets: $resets,
        phases: ($phases | each {|p| { leg: $p.leg, renewed: $p.renewed, free: $p.free, built: $p.built, evicted: $p.evicted, first_miss: $p.first_miss, last_build: $p.last_build, settled: ($p.last_build + 1), frames: ($p.last_build + 1 - $p.first_miss), boundaries: ($p.span | where {|r| $r.frame > $p.first_miss and $r.frame <= $p.last_build } | each {|r| $"($r.frame):($r.tiles_built)/($r.evicted)/($r.tiles_us)" } | str join " ") } }),
        fixed: ($fixed | first), memory_max: ($rows | get memory | math max), peak: ($peaks | first), full_at: $full,
        dumps: ($c.dumps | each {|d| { leg: $d.leg, frame: $d.frame, tiles: ($d.tiles | length) } }),
        pictures: $framed, negatives: $negatives,
    }
}

# RebuildBound: the cycle under the lift with a quota of REBUILD_TILES
# whole tiles a boundary and the stale mode, every O carrying them, so
# the record names the kept quota on every frame from the cap on. Every
# phase's R renewed keys merge at the boundary after its first miss and
# publish at exactly the frames first_miss + 1 through
# first_miss + ceil(R / REBUILD_TILES), REBUILD_TILES whole tiles at each
# before the last and the rest at the last, BUILDING 0 at every one, no
# other frame of the phase publishing; every frame after through the
# phase's dump settled; and with every retirement's entry left naming its
# slot, the cycle's sets, real eviction, accounting, and tracking
# unchanged. Returns each phase's counts and frames.
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
        let frames = (0..<$n | each {|i| $p.first_miss + 1 + $i })
        let expected = ($frames | enumerate | each {|e| { frame: $e.item, tiles_built: (if $e.index < ($n - 1) { $REBUILD_TILES } else { $p.renewed - $REBUILD_TILES * ($n - 1) }), building: 0 } })
        let read = ($frames | each {|f| $p.span | where frame == $f | get -o 0 | default { frame: $f, tiles_built: null, building: null } | select frame tiles_built building })
        let wrong = ($read | zip $expected | where {|w| $w.0 != $w.1 } | each {|w| $w.0 })
        assert ($wrong | is-empty) $"($label): the ($p.leg) phase's ($p.renewed) keys published at frames ($p.first_miss + 1) through ($p.first_miss + $n), ($REBUILD_TILES) whole tiles at each before the last and BUILDING 0 at every one: ($wrong | first 3)"
        let elsewhere = ($p.published | where {|f| $f not-in $frames })
        assert ($elsewhere | is-empty) $"($label): no other frame of the ($p.leg) phase published: ($elsewhere | first 3)"
    }
    assert-tracking $c $label
    {
        bay_keys: ($c.sets.bay | length), spawn_keys: ($c.sets.spawn | length), union: $union, cap: $CAP, resets: $resets, quota: $quota,
        phases: ($phases | each {|p| { leg: $p.leg, renewed: $p.renewed, free: $p.free, built: $p.built, evicted: $p.evicted, first_miss: $p.first_miss, last_build: $p.last_build, boundaries: ($p.published | length), counts: ($p.span | where {|r| $r.tiles_built > 0 } | get tiles_built | str join " ") } }),
    }
}

# HeldPartial: the spawn's construction held partial under the lift, a
# quota of HELD_TILES tiles and HELD_ROWS rows, and ONCE, through the
# screen and E. Established first: one publishing frame after the O, the
# one after its first miss, HELD_TILES whole tiles; BUILDING 1 from it
# through the end marker; the dump's one BUILDING tile at row HELD_ROWS;
# the displayed frame after that boundary and before the end marker; the
# measurement complete and valid; E written after the screen completed.
# Then its picture refused once, unsettled at every frame from the one
# after the construction through the displayed one, BUILDING 1 among the
# fields. Returns the frames and the refusal.
export def held-partial [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let label = "the held partial"
    let modes = ($LIFTED + $ONCE)
    let quota = ($HELD_TILES * $TILE_TEXELS + $HELD_ROWS * $TILE_ROW_TEXELS)
    let ended = { at: ($HELD_END_AT * 1ms), bytes: (pose command-frame "E") }
    let sends = [
        { at: ($STAMP_AT * 1ms), bytes: (raise-frame 0 --stamp) }
        { at: ($HELD_AT * 1ms), bytes: (pose pose-frame $SPAWN) }
        { at: (($HELD_AT + $HELD_ONCE_AFTER) * 1ms), bytes: (pool-frame --modes $modes --cold --quota $quota) }
        { at: ($HELD_DUMP_AT * 1ms), bytes: (dump-frame --building) }
        $ended
    ]
    let dir = ($out | path join "held")
    let run = (jab launch --kernel $kernel --image $image --out $dir --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --screen ($HELD_SCREEN_AT * 1ms) --seconds $HELD_SECONDS)
    assert equal (open --raw $run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)"
    let m = (gauge measure $run.api $LEGS)
    assert ($m.complete and $m.valid and $m.schema == 5) $"($label) complete and valid at schema 5: ($m.problems | str join '; ') ($m.invalid | str join '; ')"
    let from = ($m.rows | where {|r| $r.quota == $quota and $r.config_flags == ($modes + $QUOTA_KEPT) } | get -o 0.frame)
    assert ($from != null) $"($label): the O's lift, ONCE, and kept quota of ($quota) texels in force"
    let after = ($m.rows | where {|r| $r.frame >= $from })
    let first_miss = ($after | where {|r| $r.missed_blocks > 0 } | get -o 0.frame)
    assert ($first_miss != null) $"($label): the cold start's view drew blocks without their tiles from frame ($from)"
    let published = ($after | where {|r| $r.tiles_built > 0 } | select frame tiles_built)
    assert ($published == [{ frame: ($first_miss + 1), tiles_built: $HELD_TILES }]) $"($label): one publishing frame after the O, the one after its first miss, ($first_miss + 1), ($HELD_TILES) whole tiles: ($published | first 3)"
    let unheld = ($m.rows | where {|r| $r.frame > $first_miss and $r.building != 1 })
    assert ($unheld | is-empty) $"($label): BUILDING 1 on every frame from ($first_miss + 1) through the end marker's, ($m.final): ($unheld | first 3 | select frame building tiles_built)"
    let read = (dump-keys ($dir | path join "api.out") ($dir | path join "keys.nuon"))
    assert ($read.problems | is-empty) $"($label)'s dump read whole: ($read.problems | first 3)"
    assert equal ($read.dumps | length) 1 $"($label) dumped once"
    let building = ($read.dumps | get 0 | where state == $DUMP_BUILDING | select slot key row)
    assert ((($building | length) == 1) and (($building | get 0.row) == $HELD_ROWS)) $"($label)'s dump holds one BUILDING tile, at row ($HELD_ROWS): ($building)"
    let e_index = ($sends | enumerate | where {|x| $x.item.at == $ended.at and $x.item.bytes == $ended.bytes } | get 0.index)
    let e = { label: $label, measure: $m, api: $run.api, legs: $LEGS, capture: (capture-of $run.screen), from: $from, completed: $run.screen_completed, ended: ($run.send_seconds | get $e_index) }
    assert ($e.capture != null) $"($label)'s screen taken"
    let stamp = (stamp-of $e.capture)
    let window = (picture-window $m $from)
    assert equal $window.last_build ($first_miss + 1) $"($label)'s window from the construction's frame"
    let displayed = (if $stamp == null { null } else { displayed-frame $m $window $stamp })
    assert ($displayed != null) $"($label)'s stamp ($stamp) names a frame after the construction's, ($first_miss + 1), and before the end marker's, ($m.final)"
    assert ($e.completed != null and $e.ended != null) $"($label)'s screen completion and E's write recorded: ($e.completed) and ($e.ended)"
    assert ($e.ended > $e.completed) $"($label)'s E written after its screen completed: at ($e.ended) s, the screen at ($e.completed) s"
    let refused = (picture-refusals $e)
    let expected = (($first_miss + 2)..$displayed | each {|f| $f })
    assert ((($refused | length) == 1) and (($refused | get 0.kind) == "unsettled") and (($refused | get 0.frames) == $expected) and ($refused | get 0.detail | str contains "building 1")) $"($label)'s picture refused once, unsettled at every frame from ($first_miss + 2) through the displayed one, ($displayed), BUILDING 1 among the fields: ($refused | each {|r| $'($r.kind): ($r.detail)' } | str join '; ')"
    { from: $from, first_miss: $first_miss, displayed: $displayed, final: $m.final, completed: $e.completed, ended: $e.ended, building: ($building | get 0), refused: ($refused | get 0 | reject frames) }
}

def main [kernel: path, image: path, disk: path, out: path, ...fixtures: string] {
    let asked = (if ($fixtures | is-empty) { ["cycle" "rebuild" "held"] } else { $fixtures })
    mkdir $out
    for f in $asked {
        let s = (date now)
        let result = (match $f {
            "cycle" => (eviction-cycle $kernel $image $disk $out)
            "rebuild" => (rebuild-bound $kernel $image $disk $out)
            "held" => (held-partial $kernel $image $disk $out)
            _ => (error make { msg: $"no fixture ($f)" })
        })
        let took = (((date now) - $s) / 1sec | math round --precision 1)
        { fixture: $f, seconds: $took, result: $result } | to nuon --indent 1 | save -f ($out | path join $"($f).nuon")
        print $"eviction ($f): ok in ($took) s"
    }
}
