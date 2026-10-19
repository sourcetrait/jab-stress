# mod.nu

The sdl probe's controls: `nu/bin/nuance/probe.nu sdl` run three ways in the Jab
checkout beside this one, each held to an oracle the probe does not make, and
one NUON record printed. Every file of the run is written under `out`, a
directory not yet there, which is the run's record; the stripped QEMU goes under
`work`.

- monolithic: walk for 12 s on the workspace's QEMU, with QEMU's own trace of
the device's flush and set_scanout commands written through JAB_QEMU_ARGS, which
takes a QEMU carrying the log trace backend. After every traced flush exactly
one flip's upload comes before the next traced command, and none comes anywhere
else; after every traced set_scanout exactly one switch; the reset's switch and
redraw come through virtio_gpu_reset_bh; the device's code reads in the
executable; and the record's flips are the 5 ms groups of those uploads.

- modular: bounce for 12 s on the system's QEMU where its virtio-gpu is a
module, through example/bounce/extern/qemu linked to /usr for the run alone: the
device's code reads in a module and nothing is refused. The log is then read a
second time by symbols alone, through the same gates, the immediate caller and
the frame after it, every frame named wherever its object's table answers: every
flip's upload is corroborated by a later frame in an exported virtio_gpu_*
function of the module, and the flips, switches, and the console's own are the
same make_currents in both readings. With no such QEMU installed the control is
marked not run.

- stripped: the workspace's QEMU stripped of its symbol table into `work`, its
share linked to the install's, run on bounce through the same link: the probe
exits non-zero with the anchor's refusal naming the missing table, and prints no
record.

On each QEMU the window's own make_currents are expected as measured: three
switches, the registration's, the reset's, and the set_scanout's, and two of the
console's own, the registration's first update and the reset's redraw.

`reread <record>` holds a run's record to the current reader: each control's
checks over its saved logs and trace, the probe's record recomputed by
sdl-report from its saved log, nothing run and nothing written, and every check
and count held to the record's controls.nuon. The stripped control goes unread
in one case alone: its log, held to the reader's own grammar and structure,
names an executable whose file has gone since the capture. A log missing from
the record, refused by the reader, naming no executable, or naming one deleted
at the capture is a discrepancy. Its bin: `nu/bin/nuance/sdk/controls.nu <out>
<work>`, and its `reread <record>`.

## def probe-run

One probe run, `nu/bin/nuance/probe.nu sdl <program>` for SECONDS with
`qemu_args` in JAB_QEMU_ARGS: its exit, its record where it printed one,
its stderr, and the shim log it wrote, each kept under `out` by `name`.
A run refused before its QEMU starts writes no log, and the one an
earlier probe left, told by its inode, size, and modification time
unchanged across the run, is not kept.

## def tail-of

The last lines of a run's stderr, for a failure's reason.

## def message-of

An error's message as nushell renders it on stderr, its title read
through the continuation lines it wraps onto.

## def with-link

Runs `task` with example/bounce/extern/qemu linked to `target` for the
run alone, refusing a path already taken, and removes the link after,
checked to be the one made, and extern/ with it where the run made that.

## def flip-count

Flips as the record groups them: each upload within 5 ms of the one
before joins its flip.

## def made-of

The window's make_currents of a reading, each with its place among them.

## def counts-of

How many of each kind a reading holds.

## def monolithic-of

The monolithic control's checks over a walk's shim log, QEMU's trace of
the device's flush and set_scanout commands in it, and the probe's
record of the run.

## def modular-of

The modular control's checks over a bounce's shim log on a QEMU whose
virtio-gpu is a module, and the probe's record of the run: the reading,
then the same log read a second time by symbols alone.

## def stripped-checks

The stripped control's checks: the probe failed, printed no record, and
refused at the anchor, naming the missing table.

## def main

The controls, one NUON record: each control's checks and what it read,
and `ok` where every control that ran passed.

## def discrepancies

The fields a reread holds to its record that differ, each with both
values.

## def reread-one

One control reread: `task` the current reader over its saved files, its
`fields` held to the control's record, and a raise a discrepancy itself.

## def stripped-target

The executable the stripped control's shim log names, read only through
the probe's own reader (jab sdl-log), which holds every line to the
shim's grammar and the object table to its structure first. `problem` is
the discrepancy where the log names none: the log missing from the
record or refused by the reader; object 0 absent, written `- - -`, or
naming no path or one that is not absolute, where the shim writes
/proc/self/exe's target, which always is; or object 0 naming an
executable deleted at the capture, its path ending ` (deleted)`.
Otherwise `path` is object 0's path and `gone` whether nothing is there
now.

## def reread

Rereads a controls run's record, `record` its directory, through the
current reader: each control's checks over its saved logs and trace, the
probe's record recomputed by sdl-report from its saved log, nothing run
and nothing written. Every check and count is held to the record's own
controls.nuon, one NUON record is printed naming the capture's revisions
apart from the checkouts doing the reread, and any discrepancy exits
non-zero. A control the record holds as failed before a reading, its `why`
given and no reading beside it, has no checks or counts to hold and is
marked not reread, its recorded reason kept: a control refused before its
QEMU started keeps no shim log. The stripped control is marked not reread
in one case more, a log the reader accepts naming an executable that is
gone (stripped-target); every other failure to read its log is a
discrepancy.
