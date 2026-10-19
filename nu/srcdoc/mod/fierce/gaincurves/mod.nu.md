# mod.nu

GfxScaling's gain curves (FrameCeiling.md, GfxScaling): a battery's builds,
checked and keyed as workergauge reads them, each build's critical path by leg
and over the whole route: the mean of its batches' medians with half their
range, each run's own median over the same frames with the runs' least and
greatest, the frames at or over the ceiling, and whether the mean sits under it
(MedianCeiling's CEILING_US). `settled` reads each view leg's frames after its
last building frame, `play` every frame of each leg; the whole route is every
leg's frames read together. A battery in which workergauge finds any problem is
refused before any summary, each problem named, and `table` refuses a reading
that carries one (GainCurvesRefusal). Its bin:
`nu/bin/nuance/fierce/gaincurves.nu <settled|play> <base> <out.nuon>
<label>...`; its `table` renders a reading's builds as a markdown table in
milliseconds, the module's `show`.

## def read-frames

The frames a leg's run is read on, workergauge's settled rule.

## def median-of

The median by nearest rank, workergauge's spread's.

## def reading

A set of frames' reading: its batches' medians' mean and half range,
its runs' medians' least and greatest, the frames over the ceiling.

## def curves

The battery's curves, refused before any summary when workergauge finds
a problem in it, every problem named.

## def table-of

A reading's builds as a markdown table, the legs down and the builds
across in the order named, each cell the mean of the batches' medians in
milliseconds with half their range and the runs' least and greatest
medians in brackets; the whole route's last, then the frames at or over
the ceiling of those read. A reading recording no problems field, or
carrying any problem, is refused, every problem named.
