# mod.nu

The jab_probes runner's code, reached by its descriptor through the workbench
bin's `runner` verbs, or run whole by `do.nu bench jab_probes <args>`. A series
of the SDK's sdl probes of one program in a declared order, each with the words
of its own, so a control's arms differ by what the series names alone: a
build's symbols, the API's port, the trace.

## def ready

Before the launch: refuses a `base` that exists, a label that two runs share,
or a `probe_dir` whose name is not `probe`, then makes `base` and writes the
runs as declared to `<base>/runs.nuon`.

## def main

The work: each run in its order, jab's `nu/bin/nuance/probe.nu sdl <program>`
with the run's words, from the jab checkout; its stdout, the probe's record,
saved as `<base>/<label>/record.nuon` and its stderr as `probe.err`. The probe
builds the program from the tree with the run's symbols and writes one
directory a program, `probe_dir`, retiring the last run's files at its start,
so each run's directory is copied whole to `<base>/<label>/probe` before the
next. A run that exits other than 0 raises its label, its exit, and its
stderr's last six lines, the runs after it not run. Returns the labels done.
