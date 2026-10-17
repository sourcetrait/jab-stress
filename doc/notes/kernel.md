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
| `loopreorder_mutants.nuon` | example/bounce, built with `prepare` | 1 |
| `measure_mutants.nuon` | test/harts | 1 |
| `minimums_mutants.nuon` | test/spec | 11 |
| `order_mutants.nuon` | test/purity | 1 |
| `owners_mutants.nuon` | test/owners | 6 |
| `reservation_mutants.nuon` | test/reservations | 28 |
| `selector_mutants.nuon` | the selector's holds | 24 |
| `spectable_mutants.nuon` | test/spectable | 8 |
| `stuck_mutants.nuon` | test/stuck, test/harts | 10 and 1 |
| `submitwait_mutants.nuon` | test/framecap, built with `flip_batch` | 2 |
| `walk_mutants.nuon` | walk's cadence reader and its launches | 10 |
| `worker_mutants.nuon` | test/workers, test/workerfault | 15 and 7 |

A set runs through `runners/checkout_mutants.nuon` in the Jab checkout,
one call for each program its mutants name. The call takes the set's
file as its `set`, that program's mutants in `only`, and the program as
its `control`, whose passing line is the program's name followed by
`: ok`, such as `jobs: ok`, and whose `symbols` are the build symbols the
program's test is built with, comma separated, `""` for none. A call
that runs out of time lists the mutants it did not reach as `unrun`, for
the next call's `only`. Land each call's `logs` as the data checkout's
layout note says, under `runs/kernel/<set>/<stamp>/`, or
`runs/kernel/<set>/<stamp>-<label>/` for a set run in parts.

The SubmitWait set tests a kernel candidate that a build symbol selects
([Kernel candidates](candidates.md)), so its call names `flip_batch` in
`symbols`, and test/framecap holds the candidate's own expectations. Its
`clock_on_refusal` holds on the kernel without the symbol too, and is run
again there with no symbols. The LoopReorder set tests the examples'
candidate loop the same way, its call naming `prepare`.

The selector's set mutates this repository's `kernel/timing/select.nu`,
not the Jab checkout, and runs through `kernel/timing/mutants.nu`
instead ([JointTiming's selector](timing.md)). walk's set changes a copy
of its reader or walk's source in the Jab checkout and runs through
`kernel/walk/mutants.nu` ([walk's cadence reader](walk.md)).

The feature set's run ends with a second `just test test/feature`, its
log `closing_control.log` beside the set's, to show the restored
generator rebuilding the control's image.

Every find must match exactly once in the file it names, or its mutant
is left unapplied. A change to a file that a set's finds name is checked
against each such set before it lands.
