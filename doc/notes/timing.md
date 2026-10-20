# JointTiming's selector

The module `nu/mod/kernel/timing` decides JointTiming's comparison: whether
the kernel's new presentation rule, P2, replaces the rule the kernel runs
today, P0. It reads one readings record, holds it to the declared comparison,
and writes one decision record. The rules it applies are JointTiming's
selection rule, in the Jab iter's plan for the kernel.

Its command is its bin, run under the real nu:

| Command | What it does |
|---|---|
| `nu nu/bin/nuance/kernel/timing.nu <readings> <out dir>` | Reads a readings record and writes `decision.nuon` in the directory, printing the outcome, every refusal, and every shortfall |

## The declared comparison

`nu/nuon/kernel/timing/matrix.nuon`, shaped by
`nu/type/kernel/timing/Matrix.nutype`, declares the comparison before any
run exists: the hosts and their targets, the battery each host decides by,
the factory route's legs, where eps is calibrated from, and every battery's
conditions in run order with their seeds. The box is declared; TheUser's
host is added by name when his bench joins the decision. The selector
refuses to run when the file breaks its model or contradicts itself.

## The readings

One NUON record. `strategy` is how programs that await before they draw are
handled, `reordered` or `tradeoff`. `checks` says whether P2's function
cases, its host model, and the cadence fixtures came out exact.
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
whether its reading was `valid`, with the reasons when not; and its K
violations. An fps run carries its legs, each with its critical path's
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

JointTiming's comparison writes the readings record from its readers'
outputs: the gauge's reports for the guest side, ProbeRuns' reader for the
display side, and walk's guest-only reading for the second workload. The
comparison adds K's violations, the late wakes, and the catch-ups to the
gauge's reports.
