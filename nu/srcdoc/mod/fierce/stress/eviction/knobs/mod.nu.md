# mod.nu

The eviction fixtures' knobs: the console's O, D, L, and J frames a debug build
reads, and the constants every fixture shares, the cap, a tile's sizes, the O
frame's modes, the views, the stamp's time, and the one leg a launch is measured
as.

## const CAP

the cap under which the two views' keys bracket the pool, each within
it and their union past it

## const LIFTED

the O frame's modes and the record's kept quota

## const REBUILD_TILES

RebuildBound's quota, whole tiles a boundary

## const YARD

SlotReuse's other view, its walls' materials none of the spawn's

## const STAMP_AT

the HUD's stamp from the start of every launch (raise-frame's M, before
anything else is sent): a frame's number modulo STAMP_SPAN on its screen

## const LEGS

every launch measured as one leg from the start

## def pool-frame

The console's O frame, a debug build's (`console pool`): byte 4
the modes, byte 6 a cold start, then words from byte 8: the slots, a
tier's requests, an open ring's entries, the merge's share, and the
quota, each 0 for the build's own.

## def dump-frame

The console's D frame, a debug build's: every surface's READY tiles,
and with `--building` the tile in construction too.

## def level-frame

The console's L frame (`console level`): every tile forgotten at
the next boundary, every lumel full bright first when `bright`,
construction frozen when `held`, else the quota and the allowance
lifted.

## def jobs-frame

The console's J frame, a debug build's (`console jobs`): the
delayed worker's hart in byte 4, its delay in microseconds from byte 8,
the cancel in byte 12, the faulting worker's hart in byte 13, and in
byte 14 (`--hold`) the delayed worker held in fixed bands until the
round's join reaches its position.
