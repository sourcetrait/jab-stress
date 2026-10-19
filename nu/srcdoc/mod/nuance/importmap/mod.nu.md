# mod.nu

JustToNu's import-map checker: jab's and the workbench's live trees held to
the migration contract, `assets/jab/importmap/contract.nuon` in the data
checkout beside this one, which the import maps' extractor writes. It reads
the trees whole every run, never a saved list, and refuses rather than
passes: a refusal is a change to the plan or a defect in a move.

## const CONTRACT

The data checkout's contract, at `../jab-stress-data` beside this
repository; `--contract` names another.

## def head-of

A tree's commit and whether it holds changes, recorded in the report so a
run names what it read.

## def check

`--landed` is the coherent groups that have landed, comma separated, each
a name the contract's `groups` holds; the mixed state of old and new places
is the normal case between groups. Every source of both trees is read: the
nu files outside `.git`, the targets, and `extern`, and the runners'
bodies. Signatures are read only for the files the
contract's mapped defs live in, old or new. Every rule runs and every
refusal is collected, so one run names them all. With `--out` the report,
`report.nuon`, records the contract's path and SHA-256, both trees' commits
and states, the groups landed, the counts read, and every refusal; it lands
in jab-stress-data as a run of `runs/jab/importmap/`.
