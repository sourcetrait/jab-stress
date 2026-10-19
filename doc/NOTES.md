# Notes

Agent-maintained notes on this repository's contents: what each part is
for, how to run it, and what it expects of the machine it runs on. Each
note is a file under `doc/notes/`; this file is their index.

| Note | What it covers |
|---|---|
| [fps workbench](notes/fps.md) | `fps/`: the justfiles, probes, readers, and stress fixtures for testing Jab's fps game, the pose lists they read from the data checkout, and what the recipes expect |
| [sdk workbench](notes/sdk.md) | `sdk/`: the recipes and scripts for testing the Jab SDK's tools, today the sdl probe's controls and the reread of their records, and what they expect of the machine |
| [Long-engine runners](notes/runners.md) | `runners/`: the saved bodies of the long-running test and measurement runs, and how to run one again |
| [walk's cadence reader](notes/walk.md) | `kernel/walk/` and `kernel/just/walk.just`: the reader of walk's measurement records, its recipes, what a reading checks, and what it needs |
| [JointTiming's selector](notes/timing.md) | `kernel/timing/` and `kernel/just/timing.just`: the selector that decides JointTiming's comparison, its readings, and its decision |
| [Kernel candidates](notes/candidates.md) | `kernel/export/` and `kernel/just/export.just`: kernel and example changes waiting under a build symbol, how their cases run, and how a measured kernel is exported with its provenance |
| [Fresh builds](notes/freshbuild.md) | `nu/mod/nuance/freshbuild/`: a fresh build of every tuple Jab's source builds, each artifact's SHA-256 recorded for a later build to be held to |
| [The import-map checker](notes/importmap.md) | `nu/mod/nuance/importmap/`: Jab's and the workbench's nushell trees held to the migration contract while their code moves into modules |

## Layout

The workbench's nushell code takes the layout of Jab's nushell trees, at
this repository's root:

- `nu/bin/nuance.nu`, the workbench's commands, each a verb grouped by
  concept (`nuance.nu freshbuild manifest`), one call of one module
  function, with no logic of its own; `nu/bin/nuance/` for a script that
  fits no group.
- `nu/mod/nuance/<concept>/mod.nu`, the code, one concept a directory
  module, a concept past about 500 lines split into child modules under
  it.
- `nu/nuon/nuance/<concept>/`, a module's own data, and
  `nu/type/nuance/<concept>/<Model>.nutype`, each data file's shape.
- `nu/srcdoc/`, a mirror of `bin/`, `mod/`, `type/`, and `nuon/`, each
  file's prose and reasoning in `<file>.md` beside its path; the source
  carries one summary line of 80 characters at most a definition.

A module imports another by its path relative to the importing file,
named through `path self`, `use (path self ../rules)`, so nushell parses
each module file once, and reaches Jab's through the checkout beside this
one, `../jab`, as the older code does. A bin binds each import's path
first, `const RULES = path self ../mod/nuance/importmap`, then `use
$RULES`, since its top level runs after its parse, where `path self` as a
command refuses, and a bare relative path beside a module's `path self` of
the same module is a second parse of it; an older script keeps the plain
relative path. Run a command as `nu nu/bin/nuance.nu <concept> <verb>
...`. The older trees, `fps/`, `kernel/`, `runners/`, and `sdk/`, with
their justfiles, predate the layout and move into it.
