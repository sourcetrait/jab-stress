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
| `program_mutants.nuon` | gQQhjycy0Bk | a program mutant set: each candidate built through the `jf`'s `cand-build` and tested through its `image-test`, the mutant's `fixtures` passed on, its first failure classed caught only where it is an assertion's own failure (`provenance.nu`) whose title carries the mutant's expect, unexercised where that title also says unexercised, missed otherwise, and held to the mutant's expected `class`; the control passing on a line starting with `ok` (`fps: ok` for the suite's sets, the last fixture's for the eviction set; revised from ap6BdZ4ELNf) |
| `program_mutants_reasons.nuon` | 5g6hE6ot8h5 | the census set's runner: each mutant credited where its first failure is an assertion's own (`provenance.nu`) whose title, its whitespace collapsed, carries the mutant's non-empty expect and its reason when it names one, held to its expected `credited`, true unless named, once applied, built, and run; the control, the file `control_file` names, passing on a line starting with `ok` (revised from 2CXUCU4XCM9) |
| `kernel_mutants.nuon` | M2BHJwnugU | a kernel mutant set in the checkout, `just test <program>` for each |
| `checkout_mutants.nuon` | ehquII7YV8C | a set's mutants that `only` names, in the checkout itself, inline within the run tool's 600 s bound, on the program runner's contract: the `control`, a record of its `program` and `ok`, run first unmutated and `passed` on exit 0 with a line starting with its `ok`, every selected mutant's program the control's or nothing runs; each mutant's finds applied exact-once in memory, else `unapplied` with nothing written or run, then `just test <program>`, and the files it touched written back before the next; every run's whole output, stdout then stderr, kept as `<name>.log` under `logs`, which must not exist, beside `results.nuon`, the whole result with the set's hash and the checkout's commit and status before and after; each mutant classed by `provenance.nu`'s rule, caught, unexercised, or missed, a setup failure, `unapplied` or `faulted`, satisfying no class, and held to its `class`, `caught` unless named; a `budget` in seconds, 0 for none, stops it starting a mutant the longest run so far would carry past it, those listed `unrun` for the next call's `only`; a failed control or a failed restore runs nothing more (revised from 81OGFuGAAzi, whose substring credit and lost logs left its results no evidence) |
| `gauge_mutants.nuon` | bi7K9IFr9wU | the gauge's mutants over a mirror of fps's test files, `rules-mirror` for each |
| `mutant_titles.nuon` | e1petZD11qo | each mutant log's first error read for `at_assert`, an assertion's own failure (`provenance.nu`), and `matches`, the mutant's non-empty expect in its title, each held to the mutant's expected value, true unless named (revised from cSxa2WQQMwq) |
| `poolreader_mutants.nuon` | 2rM2CVU5KzA | the pool readers' mutants, each on mirrors laid out as `fps/readers/` beside a link to jab (revised from b45PFb5sQqo) |
| `tilecensus_reader_mutants.nuon` | 7SQJSudlVhg | the tile census reader's mutants, each on a mirror laid out as `fps/readers/` beside a link to jab (revised from 8k8FFBThsgC) |
| `census_reader_mutants.nuon` | 6pn8EVDeSdL | the census reader's mutants over a census serial log |
| `image_mutants.nuon` | 2G5ATFw8HaK | prebuilt mutant images through `image-test` |

## The mutant runners' own cases

`program_mutants_cases/` holds the cases that test how the mutant runners
read a failure: `program_mutants.nuon`, `checkout_mutants.nuon`, the
census set's `program_mutants_reasons.nuon`, and the gauge set's
`mutant_titles.nuon`, which share the rule in `provenance.nu`. Each case
carries what each of them must make of it: the program runner's and the
checkout runner's `class`, the census runner's `credited`, and the titles
reader's `at_assert` and `matches`.

Run a runner with `cases.just` as its `jf`, `cases.nuon` as its `mutants`,
and `game` as its `game`. Its `ok` is `eviction reuse: ok`, and its
`cands` and `logs` go under the session's scratch directory. The program
runner's `manifest` may be empty and its `assets` and `kernel` any word;
the census runner takes `raster.S` as its `control_file` and any existing
file, such as `game/src/raster.S`, as its `manifest_file`, `assets`, and
`kernel`. The titles reader reads `logs/` with `cases.nuon`. Nothing is
built or run: `cand-build` writes an empty image, and `image-test` prints
the case's log from `logs/` and exits 1 when the log holds nushell's
error, 0 otherwise. `just -f cases.just check <logs> <results>` then holds
the run to those logs and exits, `results` the run's results saved as
NUON, and only then do its expectations count. Every result must read
`control_ok` and `every`, or `all`, true. A runner takes about a minute on
the long engine.

The checkout runner reads the cases through a scratch checkout instead,
laid out by `just -f cases.just checkout <dir>` (`checkout.nu`): a `case`
file reading `control`, a justfile whose `test cases` prints the canned
log `case` names and exits with its status, and `set.nuon`, the cases as a
set of the one program `cases`, each one edit making `case` its own name,
so every run exercises the runner's finds and its restore. Run it with
`jab` the checkout, `set` its `set.nuon`, `only` every case, `control`
`{program: cases, ok: "eviction reuse: ok"}`, and `budget` 0; then
`check` holds its `logs` to the canned logs, given the `results` table of
its `results.nuon` saved as NUON. Its result must read `control_ok`,
`every`, and `restored` true. It takes a few seconds.

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
- a mutant with an empty expect that passes on the control's lines, which
  only the control may do, left uncredited;
- four census cases, the expect at an assertion: the reason missing, a
  wrong reason, and the reason only in the source excerpt, each left
  uncredited, and the reason in the title across its wrap, credited;
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
