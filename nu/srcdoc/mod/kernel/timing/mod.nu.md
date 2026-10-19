# mod.nu

JointTiming's selector (TimingSelector): the selection rule applied to one
readings record and written as one decision record. The readings carry the
comparison as each reader gives it: P2's correctness checks, eps's calibration,
every run's figures with its host, target, workload, kernel, loop order, TIMING
flag, probe, backend, and build, the controls with their scopes, and each host's
host-limit findings. An arm is one condition's runs; its figure the median of
its runs' statistic; d the compared arm's figure less its base's, P2's less
P0's; N half the larger of the two arms' ranges of that statistic. The record
names each predicate's figures and evidence, the noise gate, and the outcome, in
the plan's order: ineligible, insufficient, regressing (the critical path or the
presentation), the second workload failing, chosen; only chosen meets the
contract.

Its bin, `nu/bin/nuance/kernel/timing.nu <readings> <out>`, writes decision.nuon
in `out`.

## const STRESS

The workbench, the checkout a decision's selector names.

## const LATE_LEGS

The late-frame legs the guest's presentation predicate reads.

## const REGRESSION_FLOOR_MS

A regression's floor: a critical-path d must pass both its N and this.

## const NOISE_GATE_MS

The noise gate: a deciding statistic's N past this is insufficient.

## const TARGETS

The targets every predicate is judged on.

## const SCOPE

What scopes a control: the arm's own host, target, kernel, loop order,
backend, and build.

## def arm-of

The runs of one condition: every field `cond` names equal.

## def figure-of

An arm's figure for a statistic, the median of its runs' values, beside
their range and their count; a run without the statistic left out.

## def compare

Two arms compared on a statistic: each one's figure, d the compared
less the base, and N half the larger range; d and N null where either
arm has no figure.

## def scope-of

An arm's scope, from its first run: the fields a control must match.

## def admitted

Whether a passing control of `kind` applies to an arm: one whose every
scope field is the arm's.

## def hosts-of

The hosts the readings hold runs of.

## def eligibility

P2's eligibility: its checks exact and no K violation in any P2 run,
fps's probed and unprobed and walk's TIMING on and off alike.

## def fps-arm

fps's unprobed arm of one kernel on a host and target.

## def leg-stat

A leg's statistic of a run, null where the run has no such leg.

## def regression

The regression rule on each host and target's unprobed fps runs: a leg
regresses when P2's critical-path d passes both its N and the floor.

## def presentation-guest

The guest's presentation on each host and target's unprobed fps runs:
on the late-frame legs P2's presented-interval 95th at most P0's plus N.

## def presentation-display

Each host's display side on each target, from its probed fps runs:
blocked with no probed condition, a named input blocker; out on an
admissible host-limit finding, the decision guest-side; admissible when
each rule's readings carry a passing shim control of their own scope,
the shown-frame 95th compared; else insufficient, a host-limit claim on
inadmissible runs among it.

## def walk-off-arm

walk's arm of a kernel and order on a host and target, TIMING off and
unprobed, the gate's own input: a TIMING-on run and a probed run are
never its, whatever is offered.

## def walk-gate

The second workload's gate on each host and target, by the strategy:
reordered, P2 prepare's walk figures at most P0 await's plus N, median
and 95th, on the TIMING-off unprobed arms alone, a missing arm or an
invalid run insufficient; tradeoff, P2 await's figures reported, held
to nothing.

## def walk-phases

Each TIMING-on walk arm's D and phases on each host and target: the
runs' medians, admissible under a passing TIMING control of the arm's
own scope, else instrumented-only.

## def noise-gate

The noise gate over every deciding comparison: each N past the gate.

## def decide

The decision over a readings record: every predicate's rows, the
noise gate, the blockers, and the outcome in the plan's order.
