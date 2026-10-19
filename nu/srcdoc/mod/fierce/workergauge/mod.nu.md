# mod.nu

WorkerGauge's reading (FrameCeiling.md, TwoWorkers): the batteries' gauge.nuon
files under one base directory, a batch a label, a build a label less its
trailing _<n>, one image drawn by different workers and grains. `settled` reads
each view leg's settled frames, those after the leg's last frame building a
cell, and checks each run's capture for one L answer a view; `play` reads every
frame of each leg. Untrimmed: per batch and leg the least, median, 95th, and
greatest of each field a run's rows hold, and of four derived per frame: the
imbalance, the slowest worker less the busy time over the workers; the
remainder, the raster less the slowest worker, the dispatch, and the barrier,
the coordinator's own time and the overlap of the three; the preparation less
the clear, which the serial backend's preparation holds and the workers' bands
take; and the critical path outside the drawing, the simulation, HUD, mix, flip,
and report with what they leave unattributed; per build the mean of its batches'
medians with half their range, and every build's difference from the first build
named. The busy time is summed elapsed job time, never CPU. The CPU: each run's
harts' shares of a core over the second an older `--threads` held, and from runs
with `--cpu` the windows the report holds (`gauge cpu windows`), per build each
hart's CPU seconds and utilization per window with the runs' least and greatest,
host-time windows never divided by frames. Each run's selection and request are
its own identity's, read through `gauge identity request`, its source and
corrections named, never the report's summary unless that is the identity's
fallback. A batch's selection is its runs' agreement, and a batch whose runs mix
the automatic and forced selections is refused even where they drew alike.
Checked first: each run complete, valid, seeded, and at the cadence asked; a
forced run drawn by the workers and grain it asked; an automatic run held to its
frame records instead, drawn at one count and one grain, and its batch's runs at
the same; and every run's identity alike, its build's flags and ELF among it,
but for the workers and grain; each run's binding, the fields its report's
identity left unrecorded, and every directory passed over named. A build is a
label less its trailing _<n> under one selection, so an automatic build is never
merged with a forced one of the same counts. Each batch and build names the
grants and the active masks its runs' frames held, schema 6's harts records,
gauge/measure's validity their judge. Its bin:
`nu/bin/nuance/fierce/workergauge.nu <settled|play> <base> <out.nuon>
<label>...`.

## const COMMAND_L

the console's L as its answer carries it, the command's byte at 4

## def spread

Least, median, 95th, and greatest by nearest rank, null-free.

## def l-answers

The L answers a run's capture holds.

## def derived

A frame's derived fields: the imbalance, null under the serial backend;
the remainder, the raster itself there; the preparation less the clear;
and the critical path less the drawing.

## def frames-of

A leg's frames as the mode reads them: every frame in play; in settled
the frames after the leg's last frame building a cell, none when no
frame built one.

## def held-alike

The identity's parts a comparison holds alike, the workers and grain
apart: the build's image, flags, and ELF among them.

## def harts-of

A run's harts' shares of a core over the second an older `--threads`
held, by hart.

## def cpu-summary

Each CPU window over a build's runs (`gauge cpu windows`): by window,
the runs holding it and those missing it, the actual interval's least
and greatest, and for each hart's thread its utilization and CPU seconds
least and greatest over the runs; none without readings.

## def analyse

- a build a label stem under one selection, never an automatic one
  merged with a forced one of the same counts
