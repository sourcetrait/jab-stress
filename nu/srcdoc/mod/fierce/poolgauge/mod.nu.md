# mod.nu

PoolCore's measurements (FrameCeiling.md's PoolMeasure): the batteries'
gauge.nuon files under one base directory, a batch a label, a build a label less
its trailing _<n>. Refused before anything is summarized, every reason named
(PoolReaderStanding): a run not complete, valid, and seeded; a run no identity
file binds by SHA-256, or whose identity's seed is not its own, resolved in a nu
of its own as TileCensus's runs are, through tilecensus/resolve's bin; a bound
directory holding no capture, or a capture holding no end marker; and in
`settled` a view leg without exactly one L, or not settled after it. Each run's
capture is read from its bound directory up to its first end marker, past which
the game goes on and nothing is read: the console's L answers, each the frame of
the state records before it, and the worst-tile probe's words where a candidate
keeps them.

`settled` reads each view leg apart (SettledWindow). Its L is the console's
answer to it, an answer between state records F - 1 and F governing frame F
(main.S's frame loop: frame_records, console_read, world_draw, state_report). A
frame is settled from schema 5 with no block drawn without its tile, no BUILDING
tile, and nothing admitted, dropped, filtered, or built (pool-holds' predicate),
and below 5 with no cell built, the only settling field its records carry. The
cold is the frames from the L to the first settled frame at or after it, the
steady every frame from there to the leg's end, each one settled. The frames
between a placement and its L, the placement's own building among them, are read
in neither. `play` reads every frame of each leg as steady.

Per batch and leg the least, median, 95th, and greatest of the drawing, the
critical path, the planes, the walls, the raster, and the tile time (the pool's
boundary from schema 5, the atlas build's construction inside its planes and
walls below it, so never set beside the other), with the frames read, the tiles
built, the frames building, and from schema 5 the construction's spread and the
frames past the allowance; settled, the cold's whole, each run's drawing and
critical path summed from the L to settling and its frames, spread over the
batch's runs, and each leg's L and settling frame; per build the mean of its
batches' medians with half their range and the difference from the first build
named; and where a run's capture carries the worst-tile probe (a candidate's
storage record: at offset 40 the frame's longest whole tile build in rdtime's
ticks, at 44 to 59 the frame's whole builds in eight u16 buckets, under 6.4 us
and then each a power of two wider, the last 409.6 us and over, the schema at 60
after them), the longest whole build in microseconds and the builds by bucket,
summed over the runs and over the batches, a probe keeping no buckets reading
zeros. Its bin: `nu/bin/nuance/fierce/poolgauge.nu <settled|play> <base>
<out.nuon> <label>...`.

## def total-of

A list's sum and greatest, its nulls dropped: 0 and null for an empty
one, which math's own refuse.

## def hist-sum

Buckets summed across a list of histograms.

## def resolve-runs

Where each requested run's capture is, or why it is refused, each
request a report and a run number in it, resolved in a nu of its own
(tilecensus_resolve.nu): the capture complete and valid, the directory
the one whose identity file binds by SHA-256, the identity's seed the
run's.

## def capture-of

A capture read in order to its first end marker: the console's L
answers, each the frame of the state records before it; the probe's
longest whole build in ticks and its whole builds by bucket, over the
storage records; and whether the marker came.

## def load

Each batch's report under `base`, by label.

## def standing-of

The runs not complete, valid, and seeded, each named.

## def facts-of

Every run's capture read from its bound directory, and the runs
refused, each named with its reasons: unbound, no capture there, or no
end marker in it.

## def settled-row

Whether a row is settled: from schema 5 pool-holds' predicate, below it no
cell built.

## def frames-of

A leg's frames as the mode reads them, with why it is refused, null when
it is not: in play every frame as steady; settled, its one L, the cold
from it to the first settled frame at or after it, and the steady every
frame from there to the leg's end, each one settled.

## def whole-of

A run's cold as a whole: its drawing and critical path summed from the
L to settling, and its frames.

## def analyse

The reading of loaded batches and their runs' captures (facts-of): per
batch and leg, per build, the differences from the first build named,
and the legs refused, each named.

## def read-or-refuse

The reading of the batches under `base`, or the refusal naming every
reason: the runs' standing first, then their binding and captures, then
the legs.
