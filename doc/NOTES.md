# Notes

Agent-maintained notes on this repository's contents: what each part is
for, how to run it, and what it expects of the machine it runs on. Each
note is a file under `doc/notes/`; this file is their index.

| Note | What it covers |
|---|---|
| [fps workbench](notes/fps.md) | `fps/`: the justfiles, probes, and mutant runners for testing Jab's fps game, the pose lists they read from the data checkout, and what the recipes expect |
| [sdk workbench](notes/sdk.md) | `sdk/`: the recipes and scripts for testing the Jab SDK's tools, today the sdl probe's controls and the reread of their records, and what they expect of the machine |
| [Long-engine runners](notes/runners.md) | `runners/`: the saved bodies of the long-running test and measurement runs, how to run one again, the mutant runners' own cases, and the checkout runner's deadline, sweep, and recovery |
| [walk's cadence reader](notes/walk.md) | `kernel/walk/` and `kernel/just/walk.just`: the reader of walk's measurement records, its recipes, what a reading checks, and what it needs |
| [Kernel mutant sets](notes/kernel.md) | The kernel's mutant sets in the data checkout: which program checks each set, and how a set runs through the checkout runner one program at a time |
| [JointTiming's selector](notes/timing.md) | `kernel/timing/` and `kernel/just/timing.just`: the selector that decides JointTiming's comparison, its readings and its decision, its holds, and its mutants |
| [Kernel candidates](notes/candidates.md) | `kernel/export/` and `kernel/just/export.just`: kernel and example changes waiting under a build symbol, how their cases run, and how a measured kernel is exported with its provenance |
