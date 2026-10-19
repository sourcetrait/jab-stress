# mod.nu

ProbeRuns' reader (ProbeRuns.md's Changes, item 3): each probed run of the
batches under one base directory read whole, then pooled per cadence and
leg. A run is read in stages, and the first that fails leaves it unread
with its refusals named, never trimmed to make counts agree: its capture,
through the gauge's own reading (`gauge identity read`, `gauge report
legs-for`, `gauge measure`), complete, valid, seeded, at the cadence its
identity asks, its capture nonce answered before its first frame; its
bundle, through `sdl bundle-check` with the guest's nonce read from the
capture's load record; its flips with their calls' bounds (`gauge measure
flips`), recorded at schema 8 and derived at schema 7; and its pairing
(`sdl pair`), admitted or ambiguous, a refused pairing leaving the run
unread. Distributions are the gauge's statistics (`gauge measure stats`),
by nearest rank and untrimmed, every time in microseconds. Its bin:
`nu/bin/nuance/fierce/proberuns.nu <base> <out.nuon> <label>...`, and its
`observer` verb for the observer sets. `run-reading` is exported for the
qualification's presentation row, which joins a probed run's reading by its
directory.

## const HZ

The guest's clock, ten million ticks a second.

## const EPS

K's tolerance, 10,000 ticks, a millisecond, walk's reader's default. K's
violations are reported, never validity: the kernel's deadline policy P0
violates K by design (JointTiming).

## const CALLS

The bounds `gauge measure flips` labels as a call's own, `recorded` and
`derived`. An `outer` bound, schema 7's load presents and a retried
frame's, holds more than its call, so a long one is no stall.

## def stamp-us

A log stamp, the shim's seconds and six digits, as whole microseconds, so a
host interval is exact.

## def longest

The longest run of trues in a list, 0 for none.

## def guest-nonce

The capture nonce the guest echoed, its load record's (kind 21), the paired
profile's guest reading for `sdl bundle-check`; null where the capture holds
no load record.

## def capture-problems

Why a run's capture is not read, each named, none where it stands:
incomplete, invalid, unseeded or seeded after its first frame, its identity
asking no cadence, its cadence never answered or answered late, its frames
at another cadence than asked, and its capture nonce never answered or
answered late.

## def stalls-of

The pairing's stalls, each call past the run's median call by more than
`sdl pair`'s 4.2 ms, split by the bound each stands on: a call's own
(`calls`), the stalls the reading names, and an outer bound (`outer`),
whose length is the load's or a retried frame's whole and never a stall.

## def frames-of

The window's presents read against the renders that select them. The log's
events in order, its flip uploads numbered from 1 as the pairing numbers
them; each render selects the latest upload before it, the one SDL's
texture holds, and its gap is the time since the render before. For each
paired present: its frame and leg, the frame's critical path, submission
age, and acceptance interval, the presented interval (AcceptanceInterval);
its upload's stamp and the interval since the upload before; the renders
selecting it; shown where one does, superseded where none does and a later
render does, unshown at the end where no render follows; its repeats, the
renders past the first; its age at the first render that shows it, both
host stamps; the interval since the shown frame before, between their first
renders; and its renders' gaps. The load's presents come back apart from
the frames, with the count of renders.

## def pooled

A set of frames pooled: the presented, upload, render, and shown intervals,
the age, the critical path, and the submission age, each by the gauge's
statistics; the frames shown, superseded, repeated, and unshown at the end,
the share shown, and the longest repeat; the longest superseded run as
given, since a run of frames is one run's and never crosses runs.

## def run-legs

A run's frames pooled whole and per leg, each leg's longest superseded run
counted within it.

## def run-reading

One probed run's directory read whole: its seed, cadence, identity source,
and capture's schema and standing; then, as far as it reads, its `stage`
(null where it reads whole) and refusals, its bundle's profile, run, reader,
and trace, its flips' source and origin, its pairing (verdict, refusals,
bracket, shifts, window, fit, stalls by bound, limits), K's violations over
its presented frames' acceptance stamps at the period of its cap, its
renders' count, the load's presents, and its frames.

## def analyse

Every run of the batches under `base`, each label a battery's directory
holding its gauge.nuon, each run's directory found beside its report
(`gauge identity dirs`), read by `run-reading`, the read ones pooled per
cadence and leg. Returned: the runs, each without its frames and with its
whole and per-leg pools; the cadences, each with its runs, their verdicts,
and its whole and per-leg pools, a pool's longest superseded run the
longest any one run holds; the unread runs with their stages and refusals;
and the pairing's limits.

## def observed

A run's capture measured for the observer control: its whole-run summary
(gauge/measure's), the problems that leave it unfit (`capture-problems`),
and whether its identity names the sdl shim.

## def labels-of

A label list a command line gives as NUON, `--probed "[a b]"`, since a
script's argv carries strings alone; anything but a list of strings refused
naming the flag, an empty list taken.

## def observer-reading

The observer sets' reading (ProbeRuns.md's Observer controls): each run of
the probed batches and of the plain batches read through `observed`, a run
whose capture does not stand or whose identity disagrees with its arm about
the shim kept out and named; the shim's effect over the fit runs by
`observer shim-effect`, the rule the qualification's shim control takes;
`admissible` only where every run fits and every measure is within its
noise.

## def observer-sets

`nu/bin/nuance/fierce/proberuns.nu observer <base> <out.nuon> --probed
"[labels]" --plain "[labels]"`: the observer reading saved as NUON, a line
a measure, the problems, and the verdict, admissible or instrumented-only.

## def line-of

A pooled summary's line: the frames shown, superseded, repeated, and
unshown, the share, and the intervals', the age's, and the critical path's
medians in milliseconds.

## def main

`nu/bin/nuance/fierce/proberuns.nu <base> <out.nuon> <label>... [--eps
ticks]`: the reading saved to `out` as NUON, a line a run and a line a
cadence and leg printed, the limits last.
