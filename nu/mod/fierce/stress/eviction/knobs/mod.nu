# The cap the two views' keys bracket, each within it, their union past
export const CAP = 512

# A tile's side in texels
export const TILE_SIDE = 64

# A tile's texels
export const TILE_TEXELS = 4096

# A tile row's texels
export const TILE_ROW_TEXELS = 64

# A tile's bytes
export const TILE_BYTES = 16384

# The O frame's lift of the quota and the allowance
export const LIFTED = 1

# The O frame's mode of construction frozen
export const FROZEN = 2

# The O frame's stale mode, a retirement's entry left naming its slot
export const STALE = 4

# The O frame's ONCE, one construction a configuration
export const ONCE = 8

# The record's flag of a quota kept
export const QUOTA_KEPT = 16

# RebuildBound's quota, whole tiles a boundary
export const REBUILD_TILES = 32

# The still copy's spawn view
export const SPAWN = { name: "spawn", x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }

# The still copy's bay view
export const BAY = { name: "bay", x: 20.0, y: 17.0, z: 1.6, yaw: 180, pitch: 5 }

# SlotReuse's other view, its walls' materials none of the spawn's
export const YARD = { name: "yard", x: 40.0, y: 6.0, z: 1.6, yaw: 90, pitch: 10 }

# When the HUD's stamp goes on, before anything else is sent, in ms
export const STAMP_AT = 1200

# Every launch measured as one leg from the start
export const LEGS = [{ name: "start", places: [], pad: [] }]

# The console's O frame: the modes, a cold start, the slots, and the quota
export def pool-frame [--modes: int = 0, --cold, --slots: int = 0, --quota: int = 0]: nothing -> binary {
    let word = {|v: int| $v | into binary | bytes at 0..<4 }
    [("O" | into binary), 0x[00 00 00], ($modes | into binary | bytes at 0..<1), 0x[00], (if $cold { 0x[01] } else { 0x[00] }), 0x[00], (do $word $slots), (do $word 0), (do $word 0), (do $word 0), (do $word $quota), (0..<36 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The console's D frame: every READY tile, the one building with a flag
export def dump-frame [--building]: nothing -> binary {
    [("D" | into binary), 0x[00 00 00], 0x[ff ff ff ff], (if $building { 0x[01] } else { 0x[00] }), (0..<55 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The console's L frame: every tile forgotten, lit full bright or held
export def level-frame [bright: bool, held: bool]: nothing -> binary {
    let flag = {|on: bool| if $on { 0x[01] } else { 0x[00] } }
    [("L" | into binary), 0x[00 00 00], (do $flag $bright), (do $flag $held), 0x[00], 0x[00], (0..<56 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The console's J frame: a worker delayed, cancelled, faulted, or held
export def jobs-frame [delayed: int, delay_us: int, cancel: bool, fault: int, --hold]: nothing -> binary {
    [("J" | into binary), 0x[00 00 00], ($delayed | into binary | bytes at 0..<1), 0x[00 00 00], ($delay_us | into binary | bytes at 0..<4), (if $cancel { 0x[01] } else { 0x[00] }), ($fault | into binary | bytes at 0..<1), (if $hold { 0x[01] } else { 0x[00] }), (0..<49 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}
