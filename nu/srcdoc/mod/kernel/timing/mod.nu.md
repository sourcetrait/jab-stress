# mod.nu

JointTiming's selector (TimingSelector): the selection rule applied to one
readings record and written as one decision record, the readings held first
to the declared comparison (ComparisonMatrix), so no rule runs over runs the
matrix does not account for. The readings carry the comparison as each reader
gives it: P2's correctness checks, eps's calibration, the freeze's exports by
role, every run's identity, condition, slot, validity, and figures, the
controls and the host limits each naming its runs. An arm is one declared
condition's runs, complete or absent; its figure the median of its runs'
statistic; d the compared arm's figure less its base's, P2's less P0's; N
half the larger of the two arms' ranges of that statistic. The record names
the validation's refusals and shortfalls, the recomputed calibration, each
predicate's figures and evidence, the noise gate, and the outcome, in the
plan's order: ineligible, refused, insufficient, regressing (the critical
path or the presentation), the second workload failing, chosen; only chosen
meets the contract, its scope provisional while the box alone is declared and
host-backed once every declared host's batteries stand.

Its bin, `nu/bin/nuance/kernel/timing.nu <readings> <out>`, writes
decision.nuon in `out`, printing the outcome, every refusal, and every
shortfall; `timing.nu calibrate <base> <out>` writes eps's calibration from a
calibration capture as calibration.nuon, the readings' `calibration` its
state, eps, and qualifying frames.

## const STRESS

The workbench, the checkout a decision's selector names.

## const JAB

jab beside the workbench, the checkout a decision's selector names beside it:
its gauge measures every capture the selector reads, the calibration's among
them, and its nutype checker holds the matrix.

## const MATRIX

The declared comparison, `nu/nuon/kernel/timing/matrix.nuon`, written from
JointTiming's steps 2 to 4: the hosts with their targets and the battery each
decides by, the factory route's legs, the calibration's source, and each
battery's conditions in its run order, its batches, runs a batch, seeds, and
runs a condition. A host joins by an edit of the file once its bench joins
the decision.

## const MODEL

The matrix's model, `nu/type/kernel/timing/Matrix.nutype`, which `matrix-of`
holds it to through jab's nutype checker.

## const LATE_LEGS

The late-frame legs the guest's presentation predicate reads.

## const REGRESSION_FLOOR_MS

A regression's floor: a critical-path d must pass both its N and this.

## const NOISE_GATE_MS

The noise gate: a deciding statistic's N past this is insufficient.

## const N_CAL

The calibration's least qualifying frames on each target, 1,000.

## const EPS_QUANTUM

eps's quantum, 100 ticks: eps a multiple of it, never under it.

## const EPS_CAP

eps's cap, 10,000 ticks, 1 ms: a calibration whose percentile passes it is
capped at it.

## const STATES

The calibration's states: calibrated, capped, short.

## const MATCH

The fields a run is matched to its declared condition by: host, target,
battery, workload, backend, kernel, order, TIMING, and the probe.

## def finite

Whether a value is a finite number: an int always, a float by its text, since
nushell 0.115.1 reads every finite number equal to `inf`.

## def matrix-of

The matrix read and held to its model, then to itself: every batch a
condition of its battery, each condition run its declared count, a seed list
for each batch and each list as many seeds as the runs a batch, every battery
on a declared host, every host deciding by batteries of its own, the
calibration's source a battery. Its problems refuse the bin before any
reading.

## def conditions-of

Every declared condition on each target of its host, its key
`host/target/battery/name`, and its slots, a position and a seed each: the
batches in order, runs a batch, position 1 the battery's first run, a slot's
seed its batch's list's at its place in the batch.

## def condition-of

The declared condition whose every matching field a run carries, or null.

## def figure-problems

The figures a valid run of its condition lacks, each named, every one
finite: K's violations on every run; an fps run's critical median and
presented 95th on every declared leg, its submission age, late wakes, and
catch-ups, a probed one's shown 95th; a walk run's presented median and 95th,
and with TIMING its D and its phases.

## def wake-delays

A kept run's wake delays, s less T in ticks, over its qualifying frames as
jab's gauge selects them (`gauge measure wake-delays`: cadence 1, a wait above
0, the final flip presented), the population the gauge's late wakes count from
too. The run's capture is measured anew through the gauge under its corrected
identity and its kept route's legs, never its kept report, and read only when
complete, valid, and its receipt stage passed, as the gauge reads K; else the
run is refused by name, why among the first three problems.

## def nearest-rank

The q-th quantile by nearest rank.

## def calibration-figures

eps by the plan's rule over runs on the targets given, each run's capture read
anew (wake-delays): each target's runs, qualifying frames, 99.9th percentile,
and those past the cap; short when a target holds under N_CAL, capped when the
larger percentile passes the cap, eps then the cap, else calibrated, eps the
larger percentile rounded up to the quantum and never under it. A capture that
cannot be read is named. The one rule the validation and `calibrate` share.

## def calibration-of

eps recomputed from the calibration's source, the conditions of its battery and
kernel on each target of its host, their runs read by calibration-figures,
complete when every such condition is complete on every target.

## def calibrate

eps from a calibration capture as its runner left it: every `run_<n>` of each
batch its `batches.nuon` lists, each run's target its corrected identity's spec,
a target the matrix does not declare refused, the figures by
calibration-figures. Written as calibration.nuon in `out`: the state, eps, the
qualifying frames by target (the readings' `calibration` takes these three),
each target's figures, the base and its runs, and the selector's identity,
taken first; the state, eps, and each target's line printed.

## def calibration-problems

The declared calibration held to the plan and to the recomputation: its state
one of STATES, its eps a multiple of the quantum within the cap unless short,
its qualifying frames each target's, its state and eps the recomputed ones.

## def control-binding

A control bound to its runs: of kind shim or timing, every run it names one of
a declared condition, its runs exactly those of two conditions apart by its
flag alone, the probe for shim and TIMING for timing; admitted later only
where it passes and both conditions are complete.

## def limit-binding

A host limit bound to its runs: a declared host, its runs exactly the probed
runs of both kernels in that host's display battery, and a claim of
admissible runs only where both kernels' shim controls are admitted.

## def validate

The readings held to the matrix before any rule. Refused: a run matching no
declared condition or at no declared slot, an identity seen twice (its id,
its directory, or its capture nonce), a slot filled twice, a role the freeze
does not name, a run not its condition's frozen export, a control or host
limit not bound to its runs, a calibration off the plan or off its
recomputation. Short: a condition's runs absent, an invalid run named with
its reasons, a figure missing, the calibration's runs incomplete or a capture
unread. A condition is complete when each slot holds a valid run with every
figure and no run of it is refused; only complete conditions' runs reach the
rule.

## def figure-of

An arm's figure for a statistic, the median of its runs' values, beside
their range and their count; a run without the statistic left out.

## def compare

Two arms compared on a statistic: each one's figure, d the compared
less the base, and N half the larger range; d and N null where either
arm has no figure.

## def arm

A complete condition's runs by its declared fields, or null where the
condition is absent or incomplete: an arm's scope is its condition's, never
read from a run.

## def leg-stat

A leg's statistic of a run, null where the run has no such leg.

## def eligibility

P2's eligibility: its checks exact and no K violation in any valid P2 run in
the readings, a condition complete or not and a run refused or not, so
incomplete evidence never hides a counterexample.

## def regression

The regression rule on each declared host and target's deciding game runs,
the battery the host's `guest` names, its unprobed conditions: a leg
regresses when P2's critical-path d passes both its N and the floor; an arm
incomplete makes the host and target insufficient.

## def presentation-guest

The guest's presentation on the same arms: on the late-frame legs P2's
presented-interval 95th at most P0's plus N.

## def presentation-display

Each declared host's display side on each target, from its display battery's
probed conditions: blocked with none declared; insufficient with one
incomplete; out on a bound host limit claiming admissible runs, the decision
guest-side; admissible when both kernels' shim controls are admitted, the
shown-frame 95th compared; else insufficient, a host limit claimed on
inadmissible runs among it.

## def walk-gate

The second workload's gate on each declared host and target, by the
strategy: reordered, P2 prepare's walk figures at most P0 await's plus N,
median and 95th, on the TIMING-off conditions alone, either incomplete
insufficient; tradeoff, P2 await's TIMING-on figures reported beside P0
await's, held to nothing.

## def walk-phases

Each TIMING-on walk condition's D on each declared host and target: its runs'
median, admissible under an admitted timing control pairing it with its off
condition, instrumented-only without one, insufficient when incomplete.

## def noise-gate

The noise gate over every deciding comparison of the hosts given: each N past
the gate.

## def outcome-of

The outcome over the given hosts' rows, in the plan's order, with their noise
gate: ineligible, refused, insufficient (eps uncalibrated, the gate passed, a
predicate short), regressing, walk_failed, chosen.

## def decide

The decision over a readings record and the matrix: the validation, then every
predicate's rows, the outcome over every declared host and over the box
alone, the scope of a chosen outcome, and the contract.

## def main

The bin's one call: the selector's identity taken first, as its code is read
(jab's `identity reader`), since the calibration's reads run for minutes; the
matrix held to its model and itself, its problems refusing before any reading;
the decision over the readings, merged with the readings' and the matrix's
SHA-256 and the selector's identity, written once as decision.nuon in `out`;
the outcome, its scope, the contract, every refusal, every shortfall, and every
blocker printed.
