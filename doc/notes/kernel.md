# The kernel's mutant sets

The kernel's mutant sets are data, kept in the data checkout beside this
repository under `assets/kernel/mutants/`. Each file is a list of
mutants. A mutant names its program, the text its failure must carry,
and its edits, each a file, the text to find in it, and the text to put
in its place.

| Set | Program | Mutants |
|---|---|---|
| `compute_mutants.nuon` | example/workers | 19 |
| `feature_mutants.nuon` | test/feature | 10 |
| `flipreceipt_mutants.nuon` | test/framecap | 4 |
| `jobs_mutants.nuon` | test/jobs | 8 |
| `measure_mutants.nuon` | test/harts | 1 |
| `minimums_mutants.nuon` | test/spec | 11 |
| `order_mutants.nuon` | test/purity | 1 |
| `reservation_mutants.nuon` | test/reservations | 28 |
| `spectable_mutants.nuon` | test/spectable | 8 |
| `stuck_mutants.nuon` | test/stuck, test/harts | 10 and 1 |
| `worker_mutants.nuon` | test/workers, test/workerfault | 15 and 7 |

A set runs through `runners/checkout_mutants.nuon` in the Jab checkout,
one call for each program its mutants name. The call takes the set's
file as its `set`, that program's mutants in `only`, and the program as
its `control`, whose passing line is the program's name followed by
`: ok`, such as `jobs: ok`. A call that runs out of time lists the
mutants it did not reach as `unrun`, for the next call's `only`. Land
each call's `logs` as the data checkout's layout note says, under
`runs/kernel/<set>/<stamp>/`, or `runs/kernel/<set>/<stamp>-<label>/`
for a set run in parts.

The feature set's run ends with a second `just test test/feature`, its
log `closing_control.log` beside the set's, to show the restored
generator rebuilding the control's image.

Every find must match exactly once in the file it names, or its mutant
is left unapplied. A change to a file that a set's finds name is checked
against each such set before it lands.
