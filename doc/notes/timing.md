# JointTiming's selector

The module `nu/mod/kernel/timing` decides JointTiming's comparison: whether
the kernel's new presentation rule, P2, replaces the rule the kernel runs
today, P0. It reads one readings record, holds it to the declared comparison,
and writes one decision record. The rules it applies are JointTiming's
selection rule, in the Jab iter's plan for the kernel.

Its command is its bin, run under the real nu:

| Command | What it does |
|---|---|
| `nu nu/bin/nuance/kernel/timing.nu <readings> <out dir>` | Reads a readings record and writes `decision.nuon` in the directory, restoring each check's landed run under its `checks/`, printing the outcome, P2's eligibility, every refusal, and every shortfall |
| `nu nu/bin/nuance/kernel/timing.nu calibrate <base> <out dir>` | Reads a calibration capture's runs and writes eps's calibration, `calibration.nuon`, in the directory, printing its state, eps, and each target's figures |
| `nu nu/bin/nuance/kernel/timing.nu readings <spec> <out dir>` | Reads every battery a spec names at the calibrated eps and writes the readings record, `readings.nuon`, in the directory, printing a line a run, then the controls and host limits |
| `nu nu/bin/nuance/kernel/timing.nu package <spec> <out tar>` | Lays TheUser's host package from the spec's frozen exports, the asset tree and route the runs played, and jab's two JointTiming benches, one tar |

## The declared comparison

`nu/nuon/kernel/timing/matrix.nuon`, shaped by
`nu/type/kernel/timing/Matrix.nutype`, declares the comparison before any
run exists: the hosts and their targets, the battery each host decides by,
the factory route's legs, where eps is calibrated from, and every battery's
conditions in run order with each batch's seeds. eps is calibrated from a
battery of its own, `calibration`, run before the comparison so that P2's
kernel carries eps before any P2 run. The box is declared; TheUser's host is
added by name when his bench joins the decision. The selector refuses to run
when the file breaks its model or contradicts itself.

## The readings

One NUON record. `strategy` is how programs that await before they draw are
handled, `reordered` or `tradeoff`. `checks` binds P2's two checks, its
function cases and the cadence fixtures, each to a landed run of the
product: the check's name, the run's directory in jab-stress-data, its
`run.nuon`'s SHA-256, and the step of the run that ran the check. The
readings carry no verdict of a check; the selector reads each from its run.
`calibration` is eps's as its producer states it: its state, `calibrated`,
`capped`, or `short`, eps in ticks, and the qualifying frames on each
target. `freeze` names the frozen exports: `images` and `kernels`, each a
table of a role and its SHA-256.

`runs` holds one record a run: its `id`, its kept directory `dir`, and its
capture `nonce`; its host (`box` for this machine), target, battery,
workload (`fps` or `walk`), backend (`headless`, `offscreen`, `window`),
kernel rule (`P0` or `P2`), loop order (`await` or `prepare`), whether
walk's phase stamps were on (`timing`), and whether it was probed; its
`position` in its battery and its `seed`; its image's and kernel's SHA-256;
whether its reading was `valid`, with the reasons when not; its
`contract`, whether its receipt sequence held so that its K could be read,
with the reason when not; and its K violations, null when its contract is
unavailable. A walk run's contract is walk's reader's, kept apart from the
reading's other rules, so an invalid run can still carry its K. An fps run
carries its legs, each with its critical path's
median and its presented interval's 95th from the acceptance interval, its
submission age's median, its late wakes, and its catch-ups, and a probed one
its shown frames' 95th. A walk run carries its presented interval's median
and 95th, and with its stamps on, its drawing and phases.

`controls` holds the observer controls, each its kind (`shim` for the SDL
probe, `timing` for walk's stamps), its host and target, the ids of the runs
of both arms it compared, and whether it passed. `host_limits` holds each
host's findings of a display limit, each its host, target, whether it rests
on admissible runs, and the ids of the probed runs it rests on.

## The validation

Before any rule, every run is matched to exactly one declared condition at
a declared position and seed. Refused, and the decision `refused`: a run no
condition declares, an identity seen twice, a slot filled twice, a run that
is not its condition's frozen export, a control or a host limit that does
not name exactly its runs, and a calibration that breaks the plan or
disagrees with its own frames. Short, and the decision `insufficient`: a
condition missing runs, an invalid run, a missing figure, and a calibration
whose runs are incomplete. Only conditions complete in every run reach the
rules. eps is recomputed from the calibration's runs: each one's capture is
measured again through jab's gauge, its frames at cadence 1 that waited and
presented give their wake delays, and the larger target's 99.9th percentile
decides eps.

## P2's eligibility

Eligibility takes one of three states. It is `demonstrated` when each check's
landed run is the one the readings bound, restored under the decision's
`checks/` directory, and its step is P2's build on the comparison's kernel
source, exited 0 with its program's passing line, and when every P2 run the
matrix declares is present, its contract available, its kernel the frozen
P2 export by SHA-256, and its K 0. It is `failed`, and the outcome
`ineligible`, when a check's step exited otherwise, or when any run on the
frozen P2 kernel with an available contract violated K, whatever else makes
that run invalid. It is `unproven`, and the outcome `insufficient`, when a
check's run is missing, changed, or not restored, or a declared P2 run is
missing, its contract unavailable, or its kernel unattributed. A missing K
is never read as 0, and a run's rule label from its export's provenance
attributes nothing: only the kernel's SHA-256 does.

## The decision

The decision record holds the validation's refusals and shortfalls, the
declared and the recomputed calibration, and every predicate by host and
target with its figures, its difference, its noise, and its evidence: the
regression on each fps leg, the guest's presentation on the late-frame legs,
each host's display side, walk's gate, and walk's phases. Beside them are
the noise gate, the blockers, the outcome, its scope, the box's own outcome,
and whether the presentation contract is met. The outcome is one of
`ineligible`, `refused`, `insufficient`, `regressing`, `walk_failed`, and
`chosen`, checked in that order; only `chosen` meets the contract,
`provisional` while the box alone is declared and `host-backed` once every
declared host's batteries stand. The record also holds the readings' and the
matrix's SHA-256 and the selector's identity, taken as it starts, so a
decision names the code that made it.

## Where the readings come from

`readings` writes the readings record from the comparison's own captures, a
spec naming them: the strategy as given, each check as a table row of its
name, its landed run, and its step, bound by the run's SHA-256, the calibration
`calibrate` wrote, the frozen exports by role and file, and each battery's
base by host and battery. Every run is read anew at the calibrated eps, its
fields from its own records: an fps run through jab's gauge, which reports K's
violations, the late wakes, and the catch-ups, a probed one through ProbeRuns'
reader as well for the frames shown; a walk run through walk's guest-only
reading. Its rule comes from its kernel export's provenance and its display
backend from its batch's environment. The shim's controls are ProbeRuns'
observer effect between each kernel's probed and unprobed runs; the TIMING
controls compare each walk arm's runs with TIMING on and off on the guest's
presented interval's median and 95th. A host limit is written where every
probed run of both kernels shows SDL rendering more than half a period slower
than the guest presents. The calibration's state, eps, and qualifying frames
are `calibrate`'s, whose population of frames is the one the gauge counts its
late wakes from.
