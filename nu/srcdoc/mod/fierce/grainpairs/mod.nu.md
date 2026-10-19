# mod.nu

ThreeWorkerGrain's reading (FrameCeiling.md): a battery's two band heights read
as matched pairs. The k-th batch of the first height, `<a>_<k>`, beside the k-th
of the second, `<b>_<k>`, and within a pair each run beside the run of the same
seed. Per run the critical path's median and 95th by nearest rank and the frames
at or over the ceiling, over the whole route and by leg, the raster's median
beside them; `settled` reads each view leg after its last building frame and
`play` every frame, gaincurves' rule. Each difference is the first height less
the second. Beside the pairs: each height's runs' least, greatest, and range,
and each batch's runs read apart. A battery in which workergauge finds any
problem is refused before any reading. Its bin:
`nu/bin/nuance/fierce/grainpairs.nu <settled|play> <base> <out.nuon> <a> <b>
<batches>`.

## def read-frames

The frames a leg's run is read on, gaincurves.nu's read-frames.

## def rank

A value by nearest rank at `q`, the median at 0.5 as gaincurves.nu's.

## def stats

A set of frames read: the critical path's median and 95th, the frames
at or over the ceiling, the raster's median, and the frames read.

## def runs-of

Each run of a batch: its seed and its frames read, by leg and whole.

## def less

Two readings' differences, the first less the second.

## def spread

A list of differences summarised: how many the first height reads
lower, equal, and higher, their mean, least, and greatest.

## def pairs

The battery's matched pairs, refused before any reading when
workergauge finds a problem in it, every problem named.

## def report

A reading printed in milliseconds: each pair's whole-route differences,
then each metric's spread, whole and by leg, and each height's runs.
