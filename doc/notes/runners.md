# Long-engine runners

`runners/` holds the bodies of the long-running test and measurement
runs, saved from the Grammar MCP's run cache so they outlive it. Each
runs on the Grammar MCP's long engine
(`rig/sourcetrait/emptwo/prototype/long`), which reports progress on the
MCP's channel.

Each file holds the nonce the body last ran under, its argument and
result types, and the body. While the server's cache still holds the
nonce, `rerun` with that nonce runs the body again with new arguments.
Otherwise, pass the body to the `run` tool with its types written as
schemas. A runner that takes `jf` calls recipes in that justfile, and the
justfiles in `fps/just/` provide them.

## Test suites

| File | Nonce | What it runs |
|---|---|---|
| `fps_suite.nuon` | idu2XbuZFUr | fps's `just test <program>`, its log saved and its gauge line returned |
| `jab_suite.nuon` | lxdJlTCbEzM | Jab's whole `just test`, its table and failures returned |
| `jab_programs.nuon` | 3qrVWWbY24S | `just test` over several programs in turn |
| `worktree_suite.nuon` | ezpNNwv1r0j | a commit's suite in a worktree, with runs of edits |
| `smoke.nuon` | goxxz3sFsiB | the development smoke, through `smoke.just` |
| `file_swap.nuon` | jelF9elHCR3 | a file replaced whole through a checked copy, then the suite |

## Mutant sets

| File | Nonce | What it runs |
|---|---|---|
| `program_mutants.nuon` | 6Is3PEi6L03 | a program mutant set against the suite: each candidate built and tested through `cand-build` and `image-test`, its first failure read against its expect |
| `program_mutants_reasons.nuon` | 2CXUCU4XCM9 | the same, holding a mutant's reason in its failure's title |
| `kernel_mutants.nuon` | M2BHJwnugU | a kernel mutant set in the checkout, `just test <program>` for each |
| `gauge_mutants.nuon` | bi7K9IFr9wU | the gauge's mutants over a mirror of fps's test files, `rules-mirror` for each |
| `mutant_titles.nuon` | cSxa2WQQMwq | each mutant log's error title read for its expected head |
| `poolreader_mutants.nuon` | b45PFb5sQqo | the pool readers' mutants, each on mirrors of the readers |
| `tilecensus_reader_mutants.nuon` | 8k8FFBThsgC | the tile census reader's mutants, each on a mirror |
| `census_reader_mutants.nuon` | 6pn8EVDeSdL | the census reader's mutants over a census serial log |
| `image_mutants.nuon` | 2G5ATFw8HaK | prebuilt mutant images through `image-test` |

## Measurement

| File | Nonce | What it runs |
|---|---|---|
| `two_build_battery.nuon` | hJQcfIBaD1c | a gauge battery of two builds, batches alternated, compared field by field |
| `worker_battery.nuon` | dejKUeGaBDY | the same with each batch's workers and grain |
| `cadence_battery.nuon` | 64xTscVEoDB | gauge batches at cadences, compared |
| `cadence_image_battery.nuon` | eRABZ7iecfz | two builds at one cadence, one of them by its image |
| `route_battery.nuon` | 4i3irlI6mfU | the routes' battery on a debug image |
| `tilecensus_reading.nuon` | cnceorJbGgC | the tile census reading over batches |
| `captures_base.nuon` | f5J7eWcBJ9e | maps' poses captured on a set of images, through `poses.just` |
| `captures_compare.nuon` | 6udeEi69pqu | the same, compared with a base's captures |
| `pixel_identity.nuon` | 49AGzVbsa3Y | two sets' captures held pixel for pixel |
| `view_captures.nuon` | 9D0O2NWYvbt | a set of views captured |
| `layout_probe.nuon` | 32lvIfah9Aq | a code-layout probe, a directive aligned at a label |
| `layout_rerun.nuon` | l4cGiCZ3DTh | the layout probe's rerun |

## Kept for their record

These ran under conventions the tree or the justfiles no longer hold.

| File | Nonce | Why it no longer runs as it stands |
|---|---|---|
| `program_mutants_first.nuon` | k9CApSEhRAs | tests through a `cadence image out` recipe that no justfile here holds |
| `suite_mutants_gauge.nuon` | 9d6SqpW9Y17 | calls a three-argument `image-test` and a `gauge-read-out` recipe that no justfile here holds |
| `gauge_mutants_three.nuon` | fdIibazli7f | mirrors three test files where test.nu now imports five; `gauge_mutants.nuon` replaces it |
| `battery_adv_lsux.nuon` | lsuxWBRIVJP | calls `just adv`, which the tree no longer takes |
| `battery_adv_bv37.nuon` | bV373nxq4vo | calls `just adv` |
| `battery_adv_kiya.nuon` | kIyaQv2YFDQ | calls `just adv` and `--threads` |
| `gauge_battery_1k.nuon` | pgQsBGjuBO | the 1k cut's gauge battery |
