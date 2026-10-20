# mod.nu

The walk_battery runner's code, reached by its descriptor through the
workbench bin's `runner` verbs, or run whole by `do.nu bench walk_battery
<args>`. A battery of walk's CADENCE runs in a declared order, each batch a
condition's image and kernel on one target, every run through walk's own
wrapper, `example/walk/test/cadence.nu`, unprobed and headless, so the
conditions differ by the image and the kernel the battery names alone.

## def ready

Before the launch: refuses a `base` that exists, a label that two batches
share, or a jab checkout without walk's wrapper, then makes `base` and writes
the batches as declared to `<base>/batches.nuon`, the battery's own record of
what it was asked to run.

## def main

The work: each batch in its order, its `runs` runs one after another, each the
wrapper run from the jab checkout with the batch's `image` and `kernel`, `--spec
<spec>`, `--out <base>/<label>/run_<n>`, and `--label <label>`, every run's
stdout then stderr gathered and saved as `<base>/<label>.log` once the batch
ends. Nothing is built: each batch names a frozen export's image, its `flags`
and `walk.romfs` beside it as the wrapper reads them, and a frozen kernel. A run
that exits other than 0 saves its batch's log so far and raises its label, its
run, its exit, and its last six lines, the runs and batches after it not run.
Returns the labels done.
