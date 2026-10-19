use std/assert
use (path self ../../../../../../../jab/kit/fierce/nu/mod/picture)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/picture) [STAMP_BITS STAMP_CELL STAMP_ONE STAMP_ZERO]
use (path self ../knobs) [TILE_SIDE TILE_TEXELS]

# jab's tiles bin, run in a nu of its own for a capture's keys
const TILES = path self ../../../../../../../jab/kit/fierce/nu/bin/nuance/tiles.nu

# An API record's bytes
const RECORD = 64

# A dump header's kind in an API record, tiles' DUMP_KIND
const DUMP_KIND = 16

# The texel records a dumped tile takes, tiles' DUMP_RECORDS
const DUMP_RECORDS = 342

# A texel record's first texel byte
const DUMP_TEXELS_AT = 12

# The byte past a texel record's last texel
const DUMP_TEXELS_END = 60

# A dump header's state of a tile in construction
export const DUMP_BUILDING = 1

# The frame numbers a stamp spans before it wraps
const STAMP_SPAN = (1 bit-shl $STAMP_BITS)

# A capture's dumps keyed through the tiles bin in a nu of its own
export def dump-keys [api: path, out: path]: nothing -> record<dumps: list<any>, problems: list<any>> {
    let r = (^nu $TILES keys $api $out | complete)
    assert equal $r.exit_code 0 $"tiles.nu read the capture's dumps: ($r.stderr | str substring 0..<400)"
    open $out
}

# Whether a frame is settled: nothing missed, building, or built
export def settled [r: record]: nothing -> bool {
    $r.missed_blocks == 0 and $r.building == 0 and $r.admitted == 0 and $r.dropped == 0 and $r.filtered == 0 and $r.tiles_built == 0
}

# A frame's settling fields that are not zero, named with the frame
export def unsettled-fields [r: record]: nothing -> string {
    let broken = ([missed_blocks building admitted dropped filtered tiles_built] | where {|f| ($r | get $f) != 0 })
    $"frame ($r.frame): ($broken | each {|f| $'($f) ($r | get $f)' } | str join ', ')"
}

# A launch's screen held whole, or null when it took none
export def capture-of [screen: string]: nothing -> oneof<binary, nothing> {
    if $screen == "" { null } else { open --raw $screen | into binary }
}

# A capture with its stamp's cells written as hud.S writes a frame's
export def stamp-written [bytes: binary, value: int]: nothing -> binary {
    let head = (picture ppm-head $bytes)
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

# The window a picture's stamp must name a frame of
export def picture-window [m: record, from: int]: nothing -> record<last_build: int, final: int> {
    let published = ($m.rows | where {|r| $r.frame >= $from and $r.frame < $m.final and $r.tiles_built > 0 } | get frame)
    { last_build: (if ($published | is-empty) { $from - 1 } else { $published | last }), final: $m.final }
}

# The window's frame whose number the stamp holds, null for none
export def displayed-frame [m: record, window: record, stamp: int]: nothing -> oneof<int, nothing> {
    $m.rows | where {|r| $r.frame > $window.last_build and $r.frame < $window.final and ($r.frame mod $STAMP_SPAN) == $stamp } | get -o 0.frame
}

# A picture's refusals in prerequisite order, none when it is bound
export def picture-refusals [e: record]: nothing -> list<record<kind: string, detail: string, frames: list<int>>> {
    let m = $e.measure
    let measured = (if not $m.complete {
        [{ kind: "incomplete", detail: ($m.problems | first 3 | str join "; "), frames: [] }]
    } else if not $m.valid {
        [{ kind: "invalid", detail: ($m.invalid | first 3 | str join "; "), frames: [] }]
    } else { [] })
    let stamp = (if $e.capture == null { null } else { try { picture stamp $e.capture } catch { null } })
    let read = (if $e.capture == null {
        [{ kind: "no capture", detail: "the launch took no screen", frames: [] }]
    } else if $stamp == null {
        [{ kind: "no stamp", detail: "a cell of the stamp is neither STAMP_ONE nor STAMP_ZERO throughout", frames: [] }]
    } else { [] })
    let framed = (if ($measured | is-not-empty) or ($read | is-not-empty) { [] } else {
        let window = (picture-window $m $e.from)
        let shown = (displayed-frame $m $window $stamp)
        if ($e.published? | default false) and $window.last_build < $e.from {
            [{ kind: "no publication", detail: $"nothing published from frame ($e.from) before the end marker's, ($window.final)", frames: [] }]
        } else if $shown == null {
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

# A dumped tile's texels as its rows of bytes, read from the capture
export def tile-rows [api: binary, tile: record]: nothing -> list<binary> {
    let word = {|o: int| $api | bytes at $o..<($o + 4) | into int --endian little }
    let headers = ($api | bytes index-of --all ($DUMP_KIND | into binary | bytes at 0..<4) | where {|o| ($o mod $RECORD) == 0 } | where {|o| (do $word ($o + 4)) == $tile.slot and (do $word ($o + 8)) == $tile.key and (do $word ($o + 40)) == $tile.frame })
    assert equal ($headers | length) 1 $"one dump header of slot ($tile.slot), key ($tile.key), frame ($tile.frame)"
    let at = ($headers | first)
    let texels = (1..$DUMP_RECORDS | each {|i| $api | bytes at ($at + $i * $RECORD + $DUMP_TEXELS_AT)..<($at + $i * $RECORD + $DUMP_TEXELS_END) } | bytes collect | bytes at 0..<($TILE_TEXELS * 4))
    0..<$TILE_SIDE | each {|y| $texels | bytes at ($y * $TILE_SIDE * 4)..<(($y + 1) * $TILE_SIDE * 4) }
}

# The pixels of a row over which two captures differ, at most `most`
export def pixels-differ [p: binary, q: binary, y: int, most: int]: nothing -> list<list<int>> {
    let row = {|c: binary|
        let head = (picture ppm-head $c)
        let width = ($c | bytes at 0..<$head | decode | lines | get 1 | split row " " | first | into int)
        $c | bytes at ($head + $y * $width * 3)..<($head + ($y + 1) * $width * 3) | chunks 3
    }
    do $row $p | zip (do $row $q) | enumerate | where {|e| $e.item.0 != $e.item.1 } | first $most | each {|e| [$e.index $y] }
}
