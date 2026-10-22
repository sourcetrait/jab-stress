# mod.nu

WalkCadence's box series read whole (WalkCadence's Controls): every run of
the series a `jab_probes` run wrote under its base, each run's probe directory
read paired where its build is CADENCE's (walk/paired's paired-reading,
saved beside the record) and on the host's side from its shim's log; then each
control's effect, the oracle's reading, and the images each set built held to
the freeze's exports.

## const STRETCH_MS

A slow stretch's least host flip interval, 1.5 periods, the paired
reading's rule on the host's side.

## const STRETCH_FLIPS

The least flips a slow stretch holds.

## const JOIN_S

Uploads closer than this to the flip before join it, sdl report's grouping
of a list's uploads into one flip.

## const CONTROLS

The box series' controls: the instrumentation, TIMING against CADENCE
without it, read paired; end to end, ordinary walk against CADENCE without
TIMING, and the API port, ordinary walk with its port against without, read
on the host's side alone; a control's arms its runs by label less `_<n>`.

## const MEASURES

The measures each side reads: paired, the guest's presented interval's
median and 95th from the receipts, the presented flips' host interval's
median and 95th, the slow stretches, and the share shown; host, the flips'
interval's median and 95th, the slow stretches, and the share shown.

## def arm-of

A run's arm, its label less a trailing `_<n>`.

## def rank

A list's nearest-rank quantile, null for no values.

## def host-side

A run's host side from its shim's log: its uploads grouped into flips as
sdl report groups them, each flip's first and last upload; the intervals
between starts at the median and the 95th; the slow stretches, five or
more consecutive intervals at STRETCH_MS or past; and the share of the
flips shown: a render shows the last flip landed since the render before,
so the flips shown are the renders that found at least one, ProbeRuns'
selection rule on a paired run. sdl report's `frames_shown`, whose
`shown` counts the renders that found exactly one, rides beside it as
`report_frames_shown`.

## def paired-side

A run's measures from its paired reading, null where the reading stopped
before its flips.

The measures: the guest's presented interval from the receipts, the host's
flip interval of the presented flips, the slow stretches, and the share shown.

## def run-of

One run read: its probe's identity, its image's and kernel's SHA-256, its
CADENCE symbols, and its nonce; its paired reading where CADENCE built it,
saved as `<label>.paired.nuon` beside the record, its validity, stage,
faults, and pairing verdict kept; and its host side.

## def control-of

A control read: each measure of its side, each arm's statistic the median
of its runs', the effect the first arm's less the second's, the noise half
the larger arm's range, within when the effect's size is at most the
noise; a missing arm or a run with no reading on the side named; within
whole only with no problem and every effect within.

## def images-of

The images each set built, its runs grouped by their CADENCE symbols, every
run of a set one image, held to the export's SHA-256 `expected` names for
the set, its symbols comma separated as the probe's identity lists them.

## def main

The series under `base` read (its runs.nuon in order), the record written to
`out` with its paired readings in `<out stem>.readings` beside it, each run,
control, and set of images printed. `--expected` a NUON record of a set's
symbols to its export's image SHA-256, such as `{"CADENCE": ...,
"CADENCE,TIMING": ...}`.
