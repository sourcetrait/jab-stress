# mod.nu

JointTiming's readings assembler: the one readings record the selector reads
(`nu/mod/kernel/timing`), made from the comparison's own captures. Every run
is read anew from its kept directory, never from a report kept beside it,
and every field a run is matched to its declared condition by comes from
the run's own records: its identity, its stream, its kernel export's
provenance, and its batch's declared environment. The selector then holds
the record to the matrix; nothing here judges a run's place in it.

Its bin, `nu/bin/nuance/kernel/timing.nu readings <spec> <out>`, writes
readings.nuon in `out` and prints a line a run, then the controls and host
limits.

## The spec

One NUON record:

- `strategy`: `reordered` or `tradeoff`, as TheUser chose it.
- `checks`: `function_cases`, `model`, and `cadence_fixtures`, each true
  when exact, beside whatever evidence names them; passed through whole.
- `calibration`: `calibrate`'s calibration.nuon, or the directory holding it.
- `freeze`: `images` and `kernels`, each a table of `role` and `file`.
- `batteries`: a table of `host`, `battery`, and `base`, each base a
  gauge_batches or walk_battery battery as its runner left it.

## const STRESS

The workbench, the checkout the assembler's identity names.

## const JAB

jab beside it, whose gauge and stream modules read every run; the
assembler's identity names it beside the workbench.

## const PERIOD

The kernel's tick, 166,666, the period at the cap of 60 in the guest
clock's ticks; half of it bounds a host limit.

## const US_TICKS

The guest clock's ticks a microsecond, 10, half a period's microseconds its
divisor.

## const WALK_HEADER

The bytes of walk's stream header, read for its flags and its seed.

## def ms

Microseconds as milliseconds, null kept, the readings' unit.

## def rank

A list's nearest-rank quantile, the controls' median as ProbeRuns' and
WalkCadence's controls take it.

## def word-of

A flag's value in a gauge batch's words, `--spec` and `--runs`, refused when
the words name none, so a batch's target and size are its declaration's.

## def rule-of

A run's kernel rule from its export's provenance beside the ELF, P2 when the
build's symbols hold P2, else P0; null for a kernel no export made, which the
selector then matches to no condition.

## def roles-of

The freeze's roles, each its file's SHA-256, the frozen exports a condition
names by role.

## def calibration-of

The calibration as `calibrate` wrote it, from its file or its directory.

## def fps-run

An fps run read at eps: its identity corrected, its capture measured anew
through jab's gauge on its kept route's legs, its contract at eps. Its target
the identity's spec; its backend headless when its window is none, else
offscreen where its batch's environment sets SDL's video driver so, else a
window; its rule its kernel export's; its loop order prepare at cadences 1 and
2, which draw first, else await; probed when a shim was loaded. Valid when
ProbeRuns' capture problems name nothing, its receipts were read, its target is
its batch's, and a probed run's ProbeRuns reading passed every stage. Its
figures: each leg's critical path's median and presented interval's 95th, by
the acceptance intervals, the submission age's median, the late wakes, the
catch-ups, and K's violations; a probed run's shown frames' 95th, and kept
apart for the host limits, SDL's render interval's median and the guest's
presented interval's, all as ProbeRuns' reader pools them. Its whole summary is
kept for the shim's controls.

## def walk-run

A walk run read guest-only at eps (walk `guest-reading`): its identity's
target, kernel, and SHA-256; its stream header's seed and flags, TIMING and
PREPARE, its loop order and its stamps; valid when the reading is valid,
deciding, and on its batch's target. Its figures: the presented interval's
median and 95th from the receipts' acceptances, K's violations, and with
TIMING its drawing D, the work phase's median, and its phases.

## def battery-of

A battery's runs in its order: each batch as `batches.nuon` declares it, its
target and its runs, and each `run_<n>` under it, placed at its target's
position, the runs of that target's earlier batches before it, so a missing run
leaves the next in its own slot. A run's id is its host, battery, batch, and
run.

## def effect-of

Two arms' effect on a statistic of their valid runs: each arm's nearest-rank
median, the effect the first's less the second's, the noise half the larger of
the two ranges, within when the effect's size is at most the noise.

## def shim-controls

The shim's controls: on each host, target, battery, and kernel whose fps runs
are probed and unprobed both, ProbeRuns' observer effect (`observer
shim-effect`) over the valid runs' whole summaries, passing when admissible and
every run of both arms valid; its runs every run of both arms.

## def timing-controls

The TIMING controls: on each host, target, battery, kernel, and loop order
whose walk runs are TIMING on and off both, the guest's presented interval's
median and 95th, on against off (effect-of), passing when every run of both
arms is valid and each effect is within its noise.

## def host-limits

The hosts' display limits, ProbeRuns' branch where the host limits visible
output: on each host, target, and battery holding probed fps runs of both
kernels, a limit found when every one of those runs reads SDL's render
interval's median past the guest's presented interval's median by more than
half a period, the renders selecting every other upload or fewer. Admissible
when both kernels' shim controls pass. An entry is written only for a limit
found, the figures of every run it rests on beside it.

## def main

The readings over a spec: the assembler's identity taken first; the
calibration's eps, refused when short; every battery read at it; the strategy
and the checks as given, the calibration's state, eps, and qualifying frames,
the freeze's roles, the runs, the shim's and the TIMING controls, and the host
limits; written as readings.nuon with the spec's path and the identity, a line
printed a run and a summary after.
