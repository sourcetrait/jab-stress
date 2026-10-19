# Long-engine runners

The runners are the long-running test and measurement runs, each run on the
Grammar MCP's long engine (`rig/sourcetrait/emptwo/prototype/long`), which
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
- The hooks into jab are its own bins, run by the nu running the harness:
  the root's `nu/bin/do.nu test` and `build`, and `nuance.nu` beside it;
  fierce's `nu/bin/do.nu build --set` then `nu/bin/nuance.nu gauge run`
  for a gauge batch (`runner/gauge`, `debug` set for the debug tree and
  nothing for release, both commands' output one log, stdout then
  stderr), and its `gauge compare`; fierce's `nu/bin/nuance.nu smoke`.
  A recipe of the workbench's is its bin, passed as `nuance`: the pose
  bin for the captures, the parity bin, the tile census bin.
- `./do bench <battery> <args>` runs a harness whole in the foreground,
  its ready then its work, from a NUON file of its arguments.
- To run a runner: while the server's cache still holds its nonce, `rerun`
  that nonce with the arguments; otherwise pass the body to the `run` tool
  with its types written as schemas, and record the new nonce in the
  descriptor.

## Test suites

| Descriptor | What it runs |
|---|---|
| `fps_suite.nuon` | fierce's tests through jab's driver, `--set <set>` when `set` names any symbols, its log saved and its gauge lines returned |
| `jab_suite.nuon` | jab's whole suite through its driver, its table and failures returned, the `log` path's directory made first. Its nonce is the campaign's one cutover pass of the suite, run with a stub `just` first on its PATH, which fails and records any call |
| `jab_programs.nuon` | several programs' tests through jab's driver in turn |
| `smoke.nuon` | fierce's development smoke |

## Benches

| Descriptor | What it runs |
|---|---|
| `jab_do.nuon` | a root driver's verb in the jab checkout, `bin` `do` or `nuance`, under the environment `env` names, a table of `name` and `value`; its whole output saved to `log`, its exit and last lines returned, a non-zero exit an error, `max_quiet_min` its quiet limit in minutes. A bench and its watch are one launch each, the watch first: `nuance` `watch` `[bench <program>/<bench>]`, then `do` `bench` `[<program>/<bench>]` |

## Measurement

| Descriptor | What it runs |
|---|---|
| `two_build_battery.nuon` | a gauge battery of two builds, batches alternated, compared field by field |
| `worker_battery.nuon` | the same with each batch's workers and grain |
| `cadence_battery.nuon` | gauge batches at their cadences, compared with a baseline |
| `cadence_image_battery.nuon` | two builds at one cadence, one by its image, compared |
| `route_battery.nuon` | the routes' battery on a debug image |
| `grain_battery.nuon` | ThreeWorkerGrain's forced W 3 at 16 and 32 rows on four and eight harts |
| `scaling_batteries.nuon` | GfxScaling's selections on three, four, and eight harts, settled and factory |
| `scaling_sweep.nuon` | workers 3 to 7 at four grains on eight harts |
| `scaling_parity.nuon` | worker parity and fault steps on one kernel, each step's verdict read |
| `tilecensus_reading.nuon` | the tile census read over a battery's batches |
| `captures_base.nuon` | maps' poses captured on a set of images |
| `captures_compare.nuon` | the same, held to a base's captures |
| `pixel_identity.nuon` | sets' captures held pixel for pixel to a base set's |

Each descriptor's mirror in `nu/srcdoc/nuon/runner/` names its arguments,
and each harness module's mirror its checks and its work.

## Renamed

`jab_just.nuon` is `jab_do.nuon`: it ran `just <verb> <words>` in the jab
checkout, and runs the root's driver named by `bin` now. Its recorded runs
keep their arguments as written, and so do the runs of the runners that
took `jf`, a justfile, where `nuance` now names a bin.

## Retired

Three runners were removed, each with the reason it went:

- `layout_probe.nuon` and `layout_rerun.nuon` served TileLayout's layout
  probe, which is finished. Each saved a probed raster over the game's
  source and restored it only after its runs, so a cancel or an error
  between them left the source altered. A later layout comparison runs
  its candidates in exports, as the layout probe's `layout-cands` does.
- `view_captures.nuon` captured a set of views for the owner captures. It
  wrote a temporary map source into the game's `content/` and removed it
  after its compile. One `pose capture` call over a map now takes the same
  views.
