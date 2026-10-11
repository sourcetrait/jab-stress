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
| `program_mutants.nuon` | ap6BdZ4ELNf | a program mutant set: each candidate built through the `jf`'s `cand-build` and tested through its `image-test`, the mutant's `fixtures` passed on, its first failure classed caught only where it is an assertion's own failure whose title carries the mutant's expect, unexercised where that title also says unexercised, missed otherwise, and held to the mutant's expected `class`; the control passing on a line starting with `ok` (`fps: ok` for the suite's sets, the last fixture's for the eviction set; revised from cbCMyxedXg) |
| `program_mutants_reasons.nuon` | 2CXUCU4XCM9 | the same, holding a mutant's reason in its failure's title |
| `kernel_mutants.nuon` | M2BHJwnugU | a kernel mutant set in the checkout, `just test <program>` for each |
| `gauge_mutants.nuon` | bi7K9IFr9wU | the gauge's mutants over a mirror of fps's test files, `rules-mirror` for each |
| `mutant_titles.nuon` | cSxa2WQQMwq | each mutant log's error title read for its expected head |
| `poolreader_mutants.nuon` | 2rM2CVU5KzA | the pool readers' mutants, each on mirrors laid out as `fps/readers/` beside a link to jab (revised from b45PFb5sQqo) |
| `tilecensus_reader_mutants.nuon` | 7SQJSudlVhg | the tile census reader's mutants, each on a mirror laid out as `fps/readers/` beside a link to jab (revised from 8k8FFBThsgC) |
| `census_reader_mutants.nuon` | 6pn8EVDeSdL | the census reader's mutants over a census serial log |
| `image_mutants.nuon` | 2G5ATFw8HaK | prebuilt mutant images through `image-test` |

## The program mutant runner's own cases

`program_mutants_cases/` holds the cases that test how
`program_mutants.nuon` classes a failure. Run the runner with
`cases.just` as its `jf`, `cases.nuon` as its `mutants`, and `game` as its
`game`. Its `ok` is `eviction reuse: ok`, its `manifest` may be empty,
its `assets` and `kernel` may be any word, and its `cands` and `logs` go
under the session's scratch directory. Nothing is built or run:
`cand-build` writes an empty image, and `image-test` prints the case's log
from `logs/` and exits 1 when the log holds nushell's error, 0 otherwise.
The result must read `control_ok` and `every` true. A run takes about a
minute on the long engine.

A failure is an assertion's own when the header after the error's title
names a line of its excerpt whose code, up to the header's column, is
`assert ` or `assert equal ` at the line's start or after a `{` or a `;`,
and the label under that line is the assertion's own: `It is not true.`,
or `left:` and `right:` under a title ending `These are not equal.`. The
cases cover:

- a catch at `assert`, at `assert equal`, and at an `assert` inline after
  a block's brace, and the watchdog unexercised at its assertion;
- failures that are not an assertion's own, each missed: an unrelated
  error saying unexercised, another assertion saying unexercised, the
  expect raised between two assertions with and without unexercised, and
  an error raised while an assertion's argument evaluates;
- an empty expect at an assertion, and a mutant that passes, each missed;
- four logs that each break one part of the rule alone, each missed: a
  label other than the assertion's own at an assertion's column, the
  assertion's label at a column inside its argument, `assert equal`'s
  labels under a title not ending with its words, and its title over
  other labels.

Three logs are cut from the eviction set's saved failures, their paths
made relative to this repository, and the control's from its passing
lines. The composed logs are `shapes.nu`'s own failures, written by
`just -f cases.just compose <case>`. The four single-part logs are cut
or composed logs with one label or title line changed.

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
