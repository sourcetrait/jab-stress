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
| `checkout_mutants.nuon` | kg4fq8DXxBF | a set's mutants that `only` names, in a git checkout itself, inline, held to a `deadline` (below): the `control`, a record of its `program` and `ok`, run first unmutated and `passed` on exit 0 with a line starting with its `ok`, every selected mutant's program the control's or nothing runs; each mutant's finds applied exact-once in memory, else `unapplied` with nothing written or run, each file staged and renamed into place, then `just test <program>` under `timeout`, its marked processes swept, and its files written back the same way before the next unless the sweep left a process; every run's whole output, stdout then stderr, kept as `<name>.log` under `logs`, which must not exist, beside `baseline.nuon`, written before the control, `results.nuon`, the results whole with the sweeps and the checkout's commit and status before and after, written once, and `receipt.nuon`, the verdict: `results.nuon`'s hash, `finished`, `in_time`, and `ok`; each mutant classed by `provenance.nu`'s rule, caught, unexercised, or missed, a run the deadline cut short `overrun`, a run whose sweep left a process `unswept`, its files left for the recovery, a setup failure `unapplied` or `faulted`, none of the four satisfying a class, and held to its `class`, `caught` unless named; a mutant the time left would not hold listed `unrun` for the next call's `only`; a failed control, a failed restore, a fault, an overrun, or a survivor runs nothing more; `hold` a cancellation or delay point for the proofs, `{at: "", seconds: 0}` for none (revised from g0MevBoURaX, whose sweep scanned once, whose survivors failed nothing, and whose `finished` was read before its record) |
| `checkout_restore.nuon` | 3ExTLRGTHZA | the recovery of a checkout runner call, given the call's `logs`, one that stopped before its receipt or whose results read `cleaned` false: its marked processes ended first, nothing touched while any is left, its staged files moved under `logs/strays/<recovery>/`, and each file holding a mutation the baseline records written back from the recorded commit; a file holding anything else refused by name; `recovery-<nonce>.nuon` its record |
| `gauge_mutants.nuon` | bi7K9IFr9wU | the gauge's mutants over a mirror of fps's test files, `rules-mirror` for each |
| `mutant_titles.nuon` | e1petZD11qo | each mutant log's first error read for `at_assert`, an assertion's own failure (`provenance.nu`), and `matches`, the mutant's non-empty expect in its title, each held to the mutant's expected value, true unless named (revised from cSxa2WQQMwq) |
| `poolreader_mutants.nuon` | 2rM2CVU5KzA | the pool readers' mutants, each on mirrors laid out as `fps/readers/` beside a link to jab (revised from b45PFb5sQqo) |
| `tilecensus_reader_mutants.nuon` | 7SQJSudlVhg | the tile census reader's mutants, each on a mirror laid out as `fps/readers/` beside a link to jab (revised from 8k8FFBThsgC) |
| `census_reader_mutants.nuon` | 6pn8EVDeSdL | the census reader's mutants over a census serial log |
| `reader_holds_mutants.nuon` | 7jlg3A00NtS | the readers' own holds' mutants (`fps/mutants/workergauge_mutants.nuon`), each a `file`, `find`, `put`, and `expect`: a control and each mutant on a mirror of workergauge.nu, packetgauge.nu, lane.nu, and batches.nu laid out as `fps/readers/` beside a link to jab, four at a time, all three holds through `handoff.just`'s `reader-holds` and their output kept under `logs`, each mutant held to its expect in its failure and no raise; synchronous, a few seconds in all |
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
laid out by `just -f cases.just checkout <dir>` (`checkout.nu`). The
checkout is a git repository of its own. Its one commit holds a `case`
file reading `control` and a justfile whose `test cases` prints the canned
log `case` names and exits with its status. Beside them lie `set.nuon`,
the cases as a set of the one program `cases`, each one edit making `case`
its own name, so every run exercises the runner's finds and its restore,
and a `set_<case>.nuon` for each forced case below. Run it with `jab` the
checkout, `set` its `set.nuon`, `only` every case, `control` `{program:
cases, ok: "eviction reuse: ok"}`, `deadline` 120, `hold` `{at: "",
seconds: 0}`, and `proc` `/proc`. Then `check` holds its `logs` to the
canned logs, given the rows of its `results.nuon` that have a canned log,
saved as NUON. Its receipt must read `ok` true and hold `results.nuon`'s
hash. It takes a few seconds.

A failure is an assertion's own when the header after the error's title
names a line of its excerpt whose code, up to the header's column, is
`assert ` or `assert equal ` at the line's start or after a `{` or a `;`,
and the label under that line is the assertion's own: `It is not true.`,
or `left:` and `right:` under a title ending `These are not equal.`, each
hanging from `` `-- `` or, where its value runs across lines, from
`` `-| ``. The cases cover:

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
  other labels;
- an `assert equal` whose left value, and one whose right value, runs
  across lines, its label hanging from `` `-| ``, each caught.

Three logs are cut from the eviction set's saved failures, their paths
made relative to this repository, and the control's from its passing
lines. The composed logs are `shapes.nu`'s own failures, written by
`just -f cases.just compose <case>`. The four single-part logs are cut
or composed logs with one label or title line changed.

## The checkout runner's deadline

The checkout runner holds its call to a `deadline`, seconds from the
call's start, which ends when `results.nuon` is written: by then the
marked processes its sweeps observed are ended, the files restored and
verified, and the results recorded. A receipt reading `ok` confirms that
the cleanup and the restore succeeded and that the results were written
within the deadline; a call interrupted before its receipt, by the run
tool or the host, may need the recovery. Give the call a `timeout_ms` at
least 30 s past the deadline.
The runner keeps a margin of 15 s for the cleanup, an estimate of its
need: `timeout`'s 5 s before its KILL, the sweep's 4 s, and 6 s for the
restore and the results. The time left is the deadline less the time
spent and the margin. The runner checks it before the control and before
each mutant's first write, and starts a mutant only when it holds the
longest run so far and at least a second. Each run goes under `timeout
--signal=TERM --kill-after=5s` with the time left at its start in whole
seconds, its output written to files.

`results.nuon` is written once and never rewritten. `finished`, the
seconds from the call's start, is read after that write returns, and the
verdict follows in `receipt.nuon`: the call, `results.nuon`'s sha256 as
written, `finished`, the deadline, `in_time`, true only when `finished`
is within the deadline, and `ok`, true only when `control_ok`, `every`,
`restored`, `cleaned`, and `in_time` all are. The call returns the same.
A receipt that is absent, unreadable, or holds a hash other than
`results.nuon`'s leaves the call incomplete, never `ok`. Nothing after
the results' write is inside the deadline: a caller that needs the
verdict published inside a bound measures that boundary itself. A set's
call is read by its receipt's `ok`, a forced proof by its parts.

`guard.nu` holds the guards the runner and its recovery share:

- The mark. Each run's `timeout` carries the variable `JAB_RUNNER_MARK`,
  `<call>:<mutant>`, and every process it starts inherits it, whatever
  process group the process moves to. A nested `timeout`, such as the one
  `jab launch` wraps QEMU in, makes a group of its own, which the outer
  `timeout`'s signal never reaches.
- The sweep. After every run the sweep scans `/proc` for live processes
  carrying the call's mark, 50 ms apart while a scan finds one, and
  confirms an empty scan with the next at once: a scan lists the
  processes before it reads each, so a child started after the listing by
  a process that exits before its read is in neither. For 2 s each scan
  sends TERM to each such process it finds not yet sent TERM, and to each
  group one leads; for the next 2 s, KILL likewise. It ends `clean` at the
  second consecutive empty scan; else, once its 4 s are spent, the next
  scan's processes are `left`, and no signal goes out after. The record
  names each process, when a scan first found it, the signals sent to it
  and when, and when a scan first found it gone, beside the scans made
  and how the sweep ended. The sweep never signals the host's own process
  or group. Its claim is the marked processes its scans observed: a
  process that clears the variable, or a tree replacing itself within a
  scan's interval, is outside it.
- The atomic write. Each mutation and each restore is written to a staged
  file beside its destination, `.<name>.jabstage.<call>`, given the
  destination's mode, checked against its hash, and renamed into place,
  after which the destination must carry the staged file's inode. Through
  the runner's writes a file so holds its committed text or a recorded
  mutation, the rename replacing the name whole.
- The strays. `git ls-files --others` finds staged files anywhere in a
  checkout, ignored files included, which `git status` does not show.
- The cancel. The Grammar MCP cancels a call, at its `timeout_ms` or by
  `kill`, by setting the body's interrupt flag and sending SIGKILL to each
  external the body started and their descendants. It does not stop the
  body. A `try` that catches the interrupt, or an external a signal
  ended, clears the flag, and the body runs on with no caller. So every
  catch raises such an error again, and a cancelled call stops where the
  cancel finds it.

A run whose sweep leaves a process is classed `unswept`, ahead of
`faulted` and `overrun`, and the runner restores nothing of it: its files
stay at the recorded mutation for the recovery, which ends the processes
first and touches nothing while any remains. The call runs nothing more,
and its results read `cleaned` false.

`timeout` exits 124 when its TERM ended the run. When it must send KILL,
it sends it to its own group, itself included, so nushell reports the run
terminated by SIGKILL, exit -9, where a shell would show 137. Either, once
the run's time has passed, classes the run `overrun`. A program's own 124
before then is classed like any other exit.

Before the control the runner writes `baseline.nuon`: the call, the mark,
the checkout's commit, and each path the selection touches with its
committed hash and the hash each mutant gives it. It refuses to start,
naming each, while any process carries a runner's mark, while a staged
file lies in the checkout, or while a path it would write differs from
the commit.

A call that stopped before its receipt leaves its baseline without one,
and a call whose results read `cleaned` false leaves its files for the
recovery. `checkout_restore.nuon` takes the call's `logs` and recovers
it. It ends the call's marked processes first, and goes no further while
any is left. It moves the call's staged files into `logs/strays/<recovery>/`,
never deleting one. It writes each path holding a recorded mutation back
from `git show <commit>:<path>` of the recorded commit, staged and
renamed. A path holding anything else is refused by name and the recovery
reports itself incomplete. Run it once the call has stopped.

`hold` pins a cancellation or delay point for the proofs, outside any
catch: at `staged` or `renamed` the runner sleeps that many seconds after
a mutant's staged write or after its rename, at `finish` just before the
results' write, and at `receipt` between that write and the receipt. A
call whose `timeout_ms` falls inside the hold stops there.

The forced cases each run after the 22 in its `set_<case>.nuon`:
`overrun_sleep` sleeps, and `timeout`'s TERM ends it; `overrun_ignore`
sleeps ignoring TERM, and the sweep's KILL ends it; `overrun_nested`
leaves a nested `timeout 120` in a group of its own over a long sleep,
which the sweep finds and ends; each under a deadline of 40 s.
`cleanup_child` leaves a shell whose TERM trap starts a long sleep in a
session of its own, which a later scan of the sweep finds and ends.
`survivor` writes an entry carrying its run's mark into the stand-in that
`just -f cases.just standin <checkout> <host pid> /proc` lays out beside
the checkout as `<checkout>.proc` (`standin.nu`), once it has checked that
the entry's pid exceeds `pid_max`; with that directory as `proc`, the
entry is a process no signal ends. It proves how a survivor fails the
call and holds back the recovery, while the guest and process cases prove
the sweep on real processes. `orphan` leaves a marked sleep in a session
of its own, for the recovery's proof of a call cancelled mid-run.
`guest_spins.nuon` is the live proof against the jab checkout:
test/reservations with its program's exit replaced by a spin and its
launch's bound raised to 120 s, under a deadline of 40 s, with the control
`{program: test/reservations, ok: "reservations: ok"}`.

Each overrun proof's results must read `control_ok`, `restored`, and
`cleaned` true, the forced case alone among its `misses`, classed
`overrun`, and its receipt `in_time` true. cleanup_child's receipt must
read `ok` true. survivor's results must read `control_ok` true and
`cleaned` and `restored` false, the case alone among its misses, classed
`unswept`; the recovery refuses while the stand-in's entry is there and
completes once it is removed.

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
