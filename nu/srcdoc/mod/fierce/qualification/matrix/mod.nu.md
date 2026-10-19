# mod.nu

The qualification's matrix and what its parts share: the targets, the map every
run plays, the record's file, the cases a bench run holds, the diagnostics read
from the normal play runs, every other final obligation, the packaged bench, the
limits every reading states, the acceptance's rules, a run's agreement with the
candidate and its conditions against its step, its verdict, and the ledger and
its two verdicts, which the record writes and the check derives again, and the
helpers the candidate, the record, the check, the report, and the package all
read, jab's checkout and the workbench's among them.

## const JAB

jab checked out beside this repository, and this repository

## const TARGETS

the qualification's targets, each a named spec (the matrix)

## const MAP

the map every run plays

## const RECORD

the record's file in its directory

## const CASES

The matrix's cases a bench run holds: each its kind, acceptance,
diagnostic, or control; the reading it takes, every run's verdict, the
presentation (ProbeRuns' reader over the probed runs), the shim control
(observer.nu), or the scaling control; and each target's steps.

## const DIAGNOSTICS

The diagnostics read from the normal play runs' own frames (the matrix's
diagnostic rows): each its route legs, every leg a run holds where it
names none, and the fields of a leg's summary (gauge/measure's leg-summary).

## const OBLIGATIONS

Every final obligation no bench carries yet (ObligationLedger): the
service-active acceptance and the unavailable feature with
SceneOwnership's service, the audio with RegressionSuite's service-holds
and TheUser's host, the correctness runs and the suites at the freeze, his
Linux host's bench (U1), the Windows runs (U4), and the reports with the
evidence package; each a state and a ground by target, pending on its
dependency or not applicable for its reason, his ruling where one stands.

## def step-verb

The gauge's verb in a step's words, the first `play` or `run` after the
script: the bench files before JustToNu named `test/gauge.nu play`, after
it `nu/bin/nuance.nu gauge play`, so the verb's place moved and a fixed
index read the script's next word as the verb.

## const PACKAGED

Where a package lays each guest input a packaged step takes, by role.

## def packaged-bench

The candidate's bench as its host package runs it (HostPackage): the
preflight first, a gate, then every step of the candidate's bench file
with the package's image, kernel, and asset tree named, a route run with
the package's route, `build: none`; `{package}` stands for where the
package is extracted, filled by the bench module. The package's maker
writes it and the record holds a packaged run to it, so both read the
one transform.

## def packaged-in

A packaged bench's words as a run of it at a package's directory reads
them.

## def flag-of

The value after a flag among a step's words, null where it is absent.

## const LIMITS

What a qualification record cannot claim (Qualification.md's presentation,
CPU, and audio), stated with every reading.

## def sha-of

A file's SHA-256, null where there is none.

## def jab-file

A file of jab's at a commit, its text, null where the commit holds none.

## def ms

Milliseconds to a tenth from microseconds, a dash for none.

## def short

A commit shortened for reading.

## def same-commit

Whether a commit as an identity records it, shortened or whole, is the
candidate's.

## def agreement-of

Where a run's identity disagrees with the candidate and the target, each
disagreement named: the image's, the ELF's, and the kernel's SHA-256;
the assets' map and digest; the workspace's and the program's commits
and their changes; the machine, the target's named spec with its cores,
RAM, and display, never a custom machine or QEMU words of its own; the
cap, the target's frame rate; and the release tree.

## def finite

An int is finite; a float is finite unless its text is `inf`, `-inf`, or
`NaN`. The text, since nushell 0.115.1 compares every finite number equal
to `inf`: `1.5 == inf` reads true and `1.5 < inf` false, so a guard
written against `inf` refuses every finite value.

## def conditions-of

Where a run differs from its step's declared conditions (RederivedChecks),
each named: the workers automatic or forced to the step's count, the
cadence the step asks or the gauge's default 1, the window and the sound
live with `--host` or a play and off and recorded otherwise, the pad the
route's or the host's for a play, and the sdl probe on the probed steps
alone. A run that differs is foreign to its case, so it fails an
acceptance case and leaves a control unmet.

## def tag-state

The freeze's tag resolved in jab against the candidate's commit: met when
`qual/<n>` names it, failed when the tag is missing or names another,
pending for an untagged candidate, since no freeze stands. jab-stress's
own commit and tag are the readers' provenance and never judged.

## def verdict-of

An acceptance run's verdict (Qualification.md's acceptance): it passes
when it stands valid, holds a play median, a finite median over its valid
play window, its identity agrees with the candidate and the target, its
conditions are its step's, and its critical path's median is under the
ceiling by `gauge report under-ceiling`, the one rule; a valid run with no
finite median fails, "no play median", never passing by absence; every
problem named; the median and the tail beside it.

## def run-name

A run named for reading.

## def case-problems

A case's problems from a record: an acceptance case's missing and
reseeded runs and each run's verdict's problems; a control's reseeded
runs and its reading's problems when unmet; the presentation's reseeded
runs and its reading's problems when unread.

## def diagnostic-problems

## def ledger-of

The ledger (ObligationLedger): every final obligation on the record's
target a row with its kind, whether the bench carries it, its state, its
evidence, its ground, and its problems. The bench carries its cases, its
diagnostics, and its own agreement with its definition, `held` naming
every problem of the bench, its conditions, and its reopened inputs; the
freeze's tag is tag-state's; every other obligation OBLIGATIONS'. The
presentation's row is met only where ProbeRuns' reader read every probed
run, never a bundle directory's presence.

## def verdicts-of

The two verdicts read from a ledger, kept apart: the preparation subset's,
the rows the bench carries, passing on those alone; and the final one,
"qualification passes" only when every row is met or not applicable, else
"qualification does not pass" naming every failed row, or "qualification
incomplete" naming every pending row with its dependency. The campaign's
completion stays TheUser's acceptance; a verdict says qualification.
