# mod.nu

The qualification's matrix and what its parts share: the targets, the map every
run plays, the record's file, the cases a bench run holds, the diagnostics read
from the normal play runs, the limits every reading states, the acceptance's
rules, a run's agreement with the candidate and its verdict, which the record
writes and the check holds a record to, and the helpers the candidate, the
record, the check, and the report all read, jab's checkout and the workbench's
among them.

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
(observer.nu), or the scaling control; and each target's steps. The
matrix's other rows join with the machinery they run on: the
service-active case and the unavailable feature with SceneOwnership's
synthetic service, the audio with RegressionSuite's service-holds.

## const DIAGNOSTICS

The diagnostics read from the normal play runs' own frames (the matrix's
diagnostic rows): each its route legs, every leg a run holds where it
names none, and the fields of a leg's summary (gauge/measure's leg-summary).

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

## def verdict-of

An acceptance run's verdict (Qualification.md's acceptance): it passes
when it stands valid, its identity agrees with the candidate and the
target, and its critical path's median over its play frames is under
the ceiling by `gauge report under-ceiling`, the one rule; every problem
named; the median and the tail beside it.

## def run-name

A run named for reading.
