# Long-engine runners

The runners are the long-running test and measurement runs, each run on the
Grammar MCP's long engine (`rig/sourcetrait/two/prototype/long`), which
reports progress on the MCP's channel and keeps every packet in the
launching call's trace. A run's record, its logs and results, is kept in
the data checkout beside this repository, `../jab-stress-data`, under
`runs/<subject>/<set>/<stamp>/` with its manifest, as that repository's
`doc/notes/layout.md` lays out.

## The contract

- A runner is two parts. Its descriptor, `nu/nuon/runner/<harness>.nuon`
  (shaped by `nu/type/runner/Runner.nutype`), holds the nonce its body last
  ran as, a title, its argument and result types, and its body. Its code
  is the harness module `nu/mod/runner/<harness>/`, which exports `ready`
  and `main`.
- The body holds the long engine alone: the label, the interval, the quiet
  bound, the progress check, and the teardown. Before the launch it runs
  `nu/bin/nuance.nu runner ready <harness> <args>` and inside it `runner
  work <harness> <args>`, the workbench's bin found from the `stress`
  argument, the workbench's checkout, and run directly, since a run body
  may not run `nu` by name. The arguments go as NUON text and the answers
  come back as NUON. `ready` makes the run's directories, refuses what
  must not be there, and returns the values the progress check reads.
  `work` returns the record the run's result carries.
- A refusal or a failure is the bin's exit 1 with its message alone on
  stderr, which the body raises: a refusal before anything launches, a
  failure as the run's result. No module imports the engine's rig, so
  every module parses and runs under plain nu, and no descriptor names a
  path on this machine.
- The hooks into jab are its own bins. A recorded step runs its bin from
  its checkout's root: the root's `do` and `nu/bin/nuance.nu`, fierce's
  `nu/bin/do.nu` and `nu/bin/nuance.nu`, or a bin of the workbench's.
  `gauge_batches` runs fierce's `nuance.nu gauge run` for each batch,
  `jab_probes` jab's `nu/bin/nuance/probe.nu sdl`, and `walk_battery`
  walk's `example/walk/test/cadence.nu`, each by the nu running the
  harness.
- `./do bench <battery> <args>` runs a harness whole in the foreground,
  its ready then its work, from a NUON file of its arguments.
- To run a runner: while the server's cache still holds its nonce, `rerun`
  that nonce with the arguments; otherwise pass the body to the `run` tool
  with its types written as schemas, and record the new nonce in the
  descriptor. An empty nonce is a body that has not run since it changed.

## Recorded steps

| Descriptor | What it runs |
|---|---|
| `recorded.nuon` | steps through jab's bins or the workbench's, each under the environment its `env` names, a table of `name` and `value`, where it sets one, and each in its own directory: its output, the revisions it ran, its symbols, its kernel's and programs' builds with their digests, and the files it wrote, in `step.nuon`, the run's directory then landed whole. A suite, a program's tests, the smoke, a gauge battery and its compares, or a workbench reader's run is its step list |

## Benches

| Descriptor | What it runs |
|---|---|
| `stress_bin.nuon` | a workbench bin's verb in this checkout, `bin` its path under `nu/bin` less `.nu`, with its `verb` and `words`, under the environment `env` names, a table of `name` and `value`; its whole output saved to `log`, its exit and last lines returned, a non-zero exit an error, `max_quiet_min` its quiet limit in minutes: the qualification's `check` past the run tool's bound among them |

## Measurement

| Descriptor | What it runs |
|---|---|
| `gauge_batches.nuon` | gauge batches in a declared order, each with its own words and its own environment, nothing built: a control's arms on frozen exports |
| `jab_probes.nuon` | sdl probes of one program in a declared order, each with its own words, every run's probe directory and record copied out before the next |
| `walk_battery.nuon` | walk's CADENCE runs in a declared order through its wrapper, each batch a condition's image, kernel, spec, and run count, nothing built |

Each descriptor's mirror in `nu/srcdoc/nuon/runner/` names its arguments,
and each harness module's mirror its checks and its work.

## Retired

- Eighteen runners went with the two modules they shared, `runner/gauge`
  and `runner/captures`. Each ran once, as the move's proof, and no task
  ran it after, so each was code no task tested. Each was a list of calls
  to jab's bins or the workbench's, which `recorded` runs as its steps,
  recording each step's sources, artifacts, and outputs, so a sequence
  that named one now writes its step list. A step's `env` carries what
  `recorded` lacked, `jab_do`'s environment. The eighteen: the suites
  (`fps_suite`, `jab_suite`, `jab_programs`, `smoke`); `jab_do`; the gauge
  batteries (`two_build_battery`, `worker_battery`, `cadence_battery`,
  `cadence_image_battery`, `route_battery`, `grain_battery`,
  `scaling_batteries`, `scaling_sweep`); and the workbench readers' runs
  (`scaling_parity`, `tilecensus_reading`, `captures_base`,
  `captures_compare`, `pixel_identity`).
- `jab_just.nuon` became `jab_do.nuon`, the root's driver named by `bin`
  in place of `just`, before it went with the eighteen. Recorded runs keep
  their arguments as written, `jf` among them where a runner took a
  justfile.
- `layout_probe.nuon` and `layout_rerun.nuon` served TileLayout's layout
  probe, which is finished. Each saved a probed raster over the game's
  source and restored it only after its runs, so a cancel or an error
  between them left the source altered. A later layout comparison runs
  its candidates in exports, as the layout probe's `layout-cands` does.
- `view_captures.nuon` captured a set of views for the owner captures. It
  wrote a temporary map source into the game's `content/` and removed it
  after its compile. One `pose capture` call over a map now takes the same
  views.
