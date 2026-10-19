# mod.nu

EvictionCycle and RebuildBound: the bay and the spawn alternated under a cap,
every settle dumped, launched under the O frame's modes and quota and asserted
whole: the bracket, real eviction, the accounting, the tracking, the progress
rule, the memory, and the pictures.

## const ALLOWANCE_US

a boundary's budget: TILE_ALLOWANCE_US of time, or TILE_QUOTA's 96
tiles of texels, which a boundary stopped by it has published 96 of

## const CYCLE_LEGS

the cycle: the cap and a cold start first, then a leg a view, placed at
its start, a cold start CYCLE_COLD after on the first two, dumped
CYCLE_DUMP after, CYCLE_LEG apart; the screen CYCLE_SCREEN after the
last leg's dump while the run goes on, and E CYCLE_END after the dump,
after the screen

## const SIGHT_AT

pool-holds' settled first sight of the spawn view, the cycle's picture's
reference: the view placed with a cold start at 1500 ms, the screen at
4000 while the run goes on, and E at 4500, after it

## def cycle-launch

One cycle launched under the O frame's modes and quota, every O
carrying them: the HUD's stamp first; the cap and a cold start before
any placement, the start view's tiles within it; the bay placed with a
cold start, dumped at its settle; the spawn placed with a cold start,
dumped at its settle, the window's start; then the bay, the spawn, the
bay, and the spawn, each dumped at its settle; the screen after the
last dump while the run goes on, and E after it. The run's records
whole and valid, its dumps read whole, a dump a leg; returns the run,
its measurement and rows, each dump with its leg and view, the two
views' keys from their first sights, and E's write.

## def sight-launch

pool-holds' settled first sight of the spawn view, the cycle's
picture's reference, stamped from the start: the view placed with a
cold start at SIGHT_AT, the screen at SIGHT_SCREEN_AT while the run
goes on, E at SIGHT_END_AT after it. Returns its picture's evidence,
its window the whole run's.

## def assert-bracket

The two sets bracket the cap: each within it and their union past it.

## def assert-held

Real eviction, no reset: each settle's dump after the first sights
holds every key of its view, and tile_resets stands over the window
from the spawn's first settle. Returns the resets.

## def cycle-phases

Each phase after the first sights, from the frame after the dump before
to its own dump's: its renewed keys R, its free slots, its rows, the
builds and evictions over them, its first miss, the frames that
published, and the last of them.

## def settled-refusals

A phase's settled range read as refusals, each a kind, the frame it
names, and its detail: a dump not after the last build refused by name
before any frame is read; then each frame from the one after the last
build through the dump absent from the phase's rows or not settled.
Empty when every one of those frames, one at least, is settled.

## def assert-accounting

The accounting: each phase builds exactly its renewed keys and evicts
exactly those past its free slots; its renewed keys merge at the
boundary after its first miss; its dump after its last build, and every
frame from the one after that build through the dump settled.

## def assert-tracking

The tracking, dump to dump from the spawn's first settle: a slot
keeping its key keeps its generation, a slot taking another key steps
its generation by exactly one, every key of the returning view the dump
before held keeps its slot and generation; and every key's texels the
same in every dump that holds it.

## def eviction-cycle

EvictionCycle: the cycle under the ordinary budget. The sets bracket
the cap; real eviction and no reset; the accounting; the tracking; the
progress rule, every boundary of a phase from the one after its first
miss to its last build's, that one exempt, spending its budget, one
that published nothing among them; the memory; and the last spawn's
picture and its reference, pool-holds' settled first sight, each bound
to a validated, settled frame and equal outside the stamp. Returns each
phase's counts and frames, the run's measures, and the pictures' frames.

- the memory, from the load on
- the pictures: the last spawn's, bound to a frame of the final spawn
  phase from its last build, and its reference's, each refused for
  nothing; then the two equal outside the stamp's cells

## def rebuild-bound

RebuildBound: the cycle under the lift with a quota of REBUILD_TILES
whole tiles a boundary and the stale mode, every O carrying them, so
the record names the kept quota on every frame from the cap on. Every
phase's R renewed keys merge at the boundary after its first miss and
publish at exactly the frames first_miss + 1 through
first_miss + ceil(R / REBUILD_TILES), REBUILD_TILES whole tiles at each
before the last and the rest at the last, BUILDING 0 at every one, no
other frame of the phase publishing; every frame after through the
phase's dump settled; and with every retirement's entry left naming its
slot, the cycle's sets, real eviction, accounting, and tracking
unchanged. Returns each phase's counts and frames.
