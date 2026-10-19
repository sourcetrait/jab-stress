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

## What it does not read yet

The real readers do not yet write the readings record. The gauge's
reports do not yet carry K's violations or the late wakes, which come
with JointTiming's comparison. Until then the selector has no readings
record to read.
