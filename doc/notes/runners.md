# Long-engine runners

`runners/` holds the bodies of the long-running test and measurement
runs, saved from the Grammar MCP's run cache so they outlive it. Each
runs on the Grammar MCP's long engine
(`rig/sourcetrait/emptwo/prototype/long`), which reports progress on the
MCP's channel. A run's record, its logs and results, is kept in the data
checkout beside this repository, `../jab-stress-data`, under
`runs/<subject>/<set>/<stamp>/` with its manifest, as that repository's
`doc/notes/layout.md` lays out.

Each file holds the nonce the body last ran under, its argument and
result types, and the body. While the server's cache still holds the
nonce, `rerun` with that nonce runs the body again with new arguments.
Otherwise, pass the body to the `run` tool with its types written as
schemas. A runner that takes `jf` calls recipes in that justfile, and the
justfiles in `fps/just/` provide them.

## Test suites

| File | Nonce | What it runs |
|---|---|---|
| `fps_suite.nuon` | dAwiMIRWJx9 | fps's `just test <program>`, with `--set <set>` when `set` names any symbols, its log saved and its gauge line returned (revised from idu2XbuZFUr, which took no symbols) |
| `jab_suite.nuon` | lxdJlTCbEzM | Jab's whole `just test`, its table and failures returned; the body saves the log once the suite ends and makes no directory, so the `log` path's directory must exist before then |
| `jab_programs.nuon` | 3qrVWWbY24S | `just test` over several programs in turn |
| `smoke.nuon` | goxxz3sFsiB | the development smoke, through `smoke.just` |

## Benches

| File | Nonce | What it runs |
|---|---|---|
| `jab_just.nuon` | dR0Dw4OaNOd | `just <verb> <words>` in the jab checkout under the environment `env` names, a table of `name` and `value`, empty for none, its whole output saved to `log`, its exit and last lines returned and a non-zero exit an error, `max_quiet_min` its quiet limit in minutes: a bench's watch and the bench itself one launch each, the watch first (`watch bench <program>/<bench>`, then `bench <program>/<bench>`) |

## Measurement

| File | Nonce | What it runs |
|---|---|---|
| `two_build_battery.nuon` | hJQcfIBaD1c | a gauge battery of two builds, batches alternated, compared field by field |
| `worker_battery.nuon` | dejKUeGaBDY | the same with each batch's workers and grain |
| `cadence_battery.nuon` | hCpmZGbrBcp | gauge batches at cadences, compared, through `just do gauge` (revised from 64xTscVEoDB) |
| `cadence_image_battery.nuon` | hzJgKtbyHCA | two builds at one cadence, one of them by its image, through `just do gauge` (revised from eRABZ7iecfz) |
| `route_battery.nuon` | 4i3irlI6mfU | the routes' battery on a debug image |
| `tilecensus_reading.nuon` | cnceorJbGgC | the tile census reading over batches |
| `captures_base.nuon` | f5J7eWcBJ9e | maps' poses captured on a set of images, through `poses.just` |
| `captures_compare.nuon` | 6udeEi69pqu | the same, compared with a base's captures |
| `pixel_identity.nuon` | 49AGzVbsa3Y | two sets' captures held pixel for pixel |

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
