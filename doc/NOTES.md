# Notes

Agent-maintained notes on this repository's contents: what each part is
for, how to run it, and what it expects of the machine it runs on. Each
note is a file under `doc/notes/`; this file is their index.

| Note | What it covers |
|---|---|
| [fierce workbench](notes/fps.md) | `nu/mod/fierce/` and its probes: the readers, probes, and stress fixtures for testing Jab's fierce, the pose lists they read from the data checkout, and what they expect |
| [sdk workbench](notes/sdk.md) | `nu/mod/nuance/sdk/`: the sdl probe's controls and the reread of their records, and what they expect of the machine |
| [Long-engine runners](notes/runners.md) | `nu/nuon/runner/` and `nu/mod/runner/`: the long-running test and measurement runs, their contract, and how to run one again |
| [walk's cadence reader](notes/walk.md) | `nu/mod/kernel/walk/`: the reader of walk's measurement records, its commands, what a reading checks, and what it needs |
| [JointTiming's selector](notes/timing.md) | `nu/mod/kernel/timing/`: the selector that decides JointTiming's comparison, its readings, and its decision |
| [Kernel candidates](notes/candidates.md) | `nu/mod/kernel/freeze/`: kernel and example changes waiting under a build symbol, how their cases run, and how a measured kernel is frozen with its provenance |
| [Fresh builds](notes/freshbuild.md) | `nu/mod/nuance/freshbuild/`: a fresh build of every tuple Jab's source builds, each artifact's SHA-256 recorded for a later build to be held to |
| [The import-map checker](notes/importmap.md) | `nu/mod/nuance/importmap/`: Jab's and the workbench's nushell trees held to the migration contract while their code moves into modules |
| [Run records](notes/records.md) | `nu/mod/runner/landing/`, `log/`, and `record/`: a run landed in the data checkout with its logs as containers, restored, and reread, the one validator of its record, its models in `nu/type/data/`, and the consumer table of what each reader requires |

## Layout

The workbench's nushell code takes the layout of Jab's nushell trees, at
this repository's root:

- `do`, a link to `nu/bin/do.nu`, the casual driver: `./do bench
  <battery> <args>` runs a runner's harness whole. On Windows run `nu
  nu/bin/do.nu`.
- `nu/bin/nuance.nu`, the light commands, each a verb grouped by concept
  (`nuance.nu freshbuild manifest`, `nuance.nu fierce tiles keys`), one
  call of one module function with no logic of its own: `build` and
  `test` through jab's driver, `check`, `hot`, `importmap`, `freshbuild`,
  the census's and the tiles bin's verbs, and `runner`.
- `nu/bin/nuance/<subject>/<module>.nu`, a standalone bin for each reader,
  probe, fixture, and kernel reader, so each runs in a nu that loads its
  own module alone: a command that evaluates a closure copies every loaded
  module's state each time, and these run closures a row and time their
  launches.
- `nu/mod/<subject>/<concept>/mod.nu`, the code, one concept a directory
  module, a concept past about 500 lines split into child modules under
  it: `fierce/` the readers and the stress fixtures, `kernel/` walk's
  reader and fixture, the selector, and the kernel's freeze, `runner/` the
  runners' harnesses, their dispatcher, and the run records' validator;
  `nu/mod/nuance/` the code a nuanced command alone uses, the probes, the
  sdl controls, the checker, and the fresh build.
- `nu/nuon/<concept>/`, a module's own data, the runners' descriptors in
  `nu/nuon/runner/`, and `nu/type/<concept>/<Model>.nutype`, each data
  file's shape; the data checkout's records are shaped by `nu/type/data/`.
- `nu/srcdoc/`, a mirror of `bin/`, `mod/`, `type/`, and `nuon/`, each
  file's prose and reasoning in `<file>.md` beside its path; the source
  carries one summary line of 80 characters at most a definition.

A module imports another by its path relative to the importing file,
named through `path self`, `use (path self ../rules)`, so nushell parses
each module file once, and reaches Jab's through the checkout beside this
one, `../jab`. A bin binds each import's path first, `const RULES = path
self ../mod/nuance/importmap`, then `use $RULES`, since its top level runs
after its parse, where `path self` as a command refuses, and a bare
relative path beside a module's `path self` of the same module is a
second parse of it; `nu/bin/do.nu`, which the root's link reaches,
resolves itself first, since `path self` names the link. Code that drives
another checkout of Jab, given at run time, reaches it through that
checkout's bins and never imports its modules, whose paths a parse fixes.
