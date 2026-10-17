# JointTiming's selector

`kernel/timing/select.nu` decides JointTiming's comparison: whether the
kernel's new presentation rule, P2, replaces the rule the kernel runs
today, P0. It reads one readings record and writes one decision record.
The rules it applies are JointTiming's selection rule, in the Jab
iter's plan for the kernel.

The recipes are in `kernel/just/timing.just` and run under the real nu:

| Recipe | What it does |
|---|---|
| `just -f kernel/just/timing.just select <readings> <out dir>` | Reads a readings record and writes `decision.nuon` in the directory, printing the outcome |
| `just -f kernel/just/timing.just select-holds <script> <scratch>` | Runs the selector's own fixtures, the script named so that a mutant's copy can run in its place |
| `just -f kernel/just/timing.just select-sample <readings>` | Writes the fixtures' clean comparison as a readings record, to run `select` over |
| `just -f kernel/just/timing.just select-mutants <set> <scratch>` | Runs the selector's mutant set, each mutant expected to fail at its own hold |

## The readings

One NUON record. `strategy` is how programs that await before they draw
are handled, `reordered` or `tradeoff`. `checks` says whether P2's
function cases, its host model, and the cadence fixtures came out exact.
`calibration` is eps's: its state, `calibrated`, `capped`, or `short`,
eps in ticks, and the qualifying frames on each target.

`runs` holds one record a run. Each names its host (`box` for this
machine), its target, its workload (`fps` or `walk`), its kernel's rule
(`P0` or `P2`), its loop order (`await` or `prepare`), whether walk's
phase stamps were on (`timing`), whether it was probed, its backend, its
build, its battery and position, whether its reading was valid, and its
K violations. An fps run carries its legs, each with its critical path's
median and its presented interval's 95th, and a probed one its shown
frames' 95th. A walk run carries its presented interval's median and
95th, and with its stamps on, its drawing and phases.

`controls` holds the observer controls: each its kind (`timing` for
walk's stamps, `shim` for the SDL probe), the scope it was measured in
(host, target, kernel, order, backend, and build), and whether it
passed. `host_limits` holds each host's findings of a display limit,
each saying whether it rests on admissible runs.

## The decision

The decision record holds every predicate by host and target with its
figures, its difference, its noise, and its evidence: the regression on
each fps leg, the guest's presentation on the late-frame legs, each
host's display side, walk's gate, and walk's phases. Beside them are the
noise gate, the blockers, the outcome, and whether the presentation
contract is met. The outcome is one of `ineligible`, `insufficient`,
`regressing`, `walk_failed`, and `chosen`, checked in that order; only
`chosen` meets the contract.

## The holds and the mutants

`select-holds` builds a clean comparison on both targets and changes it
one way a case, 26 cases, each expecting one outcome or one state. The
selector's mutant set, `selector_mutants.nuon` under the data
checkout's `assets/kernel/mutants/`, removes one rule a mutant, 24 in
all. `kernel/timing/mutants.nu` runs a copy of the selector with each
mutant applied, a control first, and a mutant is caught when its holds
fail at the case it names.

## What it does not read yet

The real readers do not yet write the readings record. gauge.nu's
reports do not yet carry K's violations or the late wakes, which come
with JointTiming's comparison. Until then the selector runs on
synthetic readings alone.
