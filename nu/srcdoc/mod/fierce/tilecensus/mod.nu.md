# mod.nu

TileCensus's reading (FrameCeiling.md, TilePool): a CENSUS build's runs of the
gauge's routes, a batch a label under one base directory holding its gauge.nuon
and each run's serial.log, the census's lines read by jab's `nu/mod/census`. A
run is refused before its census is read unless its capture is complete and
valid (GaugeStanding) and its directory is the one whose identity file binds to
the run's recorded SHA-256, through `gauge identity of`, the identity's seed the
run's (CensusRunBinding), resolved in a nu of its own, tilecensus/resolve's bin,
since the gauge loaded here would slow the census's parse about eightfold; and
after, when a census frame's mapped pixels at side 32, eligible plus straddling,
pass its row's lit pixels, the two files then not one run's. A refused run is
summarized nowhere. Every census frame of an accepted run takes the leg the
gauge's row of the same frame names; frames past the measurement's final frame
are counted outside and read no further. A frame stands valid as census judges
it, whole and accounting; a working set over 30 or 120 frames stands only when
every frame of its window is present and valid, the window whole since the
census's first frame. Per batch, side, and leg, and over every leg: the eligible
and straddling blocks and their shares, the demand by class, the sampled and
uniformly lit tiles, the working sets by class, the requesting surfaces, each
context's requests, distinct tiles, and surfaces, the distinct tiles a surface
asks of a context in a frame, and the open ring's fill past each guarantee in
GUARANTEES, a context's distinct tiles past each surface's first G summed, these
for every surface and again for the walls with their openings alone, the
surfaces from the directory's planes-below on, the class TILE_CLASSES caches
first; untrimmed, by nearest rank. Beside them the directory's bytes and the
pool's slots at each side for each size in POOLS_MIB. Problems named besides: a
refusal, the rows not every frame from 0, no directory, the edge's verdicts not
both 0, a gap, a measured frame with no census or invalid, a mismatch, more than
one lighting revision. Its bin: `nu/bin/nuance/fierce/tilecensus.nu <base>
<out.nuon> <label>...`.

## const BOUND_SIDE

the side whose mapped pixels are held to the rows' lit pixels

## def spread

Least, median, 95th, 99th, and greatest by nearest rank, nulls dropped.

## def sum-of

A sum that reads an empty list as 0, where math sum refuses it.

## def fills-of

The open ring's fill past each guarantee: the counts past G summed.

## def context-of

A context's list folded to what the summaries read: its counts and the
open ring's fill past each guarantee, for every surface and for the walls
with their openings alone, the surfaces from `below`, the directory's
planes-below, the class TILE_CLASSES caches first.

## def resolve-runs

Where each requested run's census is, or why it is refused before it is
read, each request a report and a run number in it, resolved in a nu of
its own (tilecensus_resolve.nu): GaugeStanding and CensusRunBinding.

## def census-of

A resolved run's census: its rows' legs, its census frames, the measured
ones marked with their leg and their windows' standing, the frames whose
mapped pixels pass their rows' lit pixels, and what keeps it from whole.

## def run-of

One run of a batch under its resolution: refused, or its census read,
refused whole when a frame's mapped pixels pass its row's lit pixels.

## def side-summary

A side's records, one a measured frame, summarised, each of the
`context_count` contexts its directories count on its own.

## def analyse

- the contexts the accepted runs' directories count, never the
  context lines that arrived
