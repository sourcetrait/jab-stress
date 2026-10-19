# The sdk workbench

The workbench's code for testing the Jab SDK's tools beyond their own
suite, today the sdl probe's controls, the module
`nu/mod/nuance/sdk/controls`. A run's record is kept in the data checkout
beside this repository, `../jab-stress-data`, under `runs/sdk/`.

## The sdl probe's controls

`nu nu/bin/nuance/sdk/controls.nu <out> <work>` runs the SDK's probe,
`nu/bin/nuance/probe.nu sdl`, three times in the Jab checkout beside this
one, `../jab`, and holds each run to an oracle the probe does not make
itself. It prints one NUON record and exits non-zero when a control that
ran has failed. Every file of the run is written under `<out>`, which must
not exist yet, and that directory is the run's record. The stripped QEMU
goes under `<work>`, outside the record. A run takes about a minute. A
control's shim log is kept in the record only when the run wrote it: a
control refused before QEMU started leaves the log of an earlier run,
which is left out.

- `monolithic` runs `example/walk` for 12 seconds on the workspace's
  QEMU, with QEMU's own trace of the virtio-gpu device's flush and
  set_scanout commands passed through `JAB_QEMU_ARGS`. It needs a QEMU
  built with the log trace backend, as the workspace's `extern/qemu` is.
  It checks that every traced flush is followed by exactly one flip's
  upload before the next traced command, and that no upload comes
  anywhere else. It checks that every traced set_scanout is followed by
  exactly one switch, that the device's reset makes one switch and one
  redraw, that the device's code reads in the executable, and that the
  record's flips are those uploads grouped by 5 ms.
- `modular` runs `example/bounce` for 12 seconds on the system's QEMU at
  `/usr`, where virtio-gpu is a module, as in Fedora's and Ubuntu's
  packages. It links `example/bounce/extern/qemu` to `/usr` for the run
  and removes the link afterwards, and it refuses to start when that path
  is already taken. It checks that the device's code reads in a module
  and that nothing is refused. Then it reads the same log a second time
  by symbols alone, every frame named wherever its file's symbol table
  answers. It checks that every flip's upload has a later frame in an
  exported `virtio_gpu_*` function of the module, and that the flips, the
  switches, and the console's own updates are the same make_currents in
  both readings. With no such QEMU installed, the record marks the
  control as not run.
- `stripped` strips the workspace's QEMU of its symbol table into
  `<work>/stripped/`, links its `share` to the install's, and runs
  `example/bounce` on it through the same link. It checks that the probe
  exits non-zero with the refusal that names the missing table, and that
  it prints no record.

On both QEMUs the window is expected to make three switches, for the
display's registration, the device's reset, and the program's
set_scanout, and two of the console's own updates, the registration's
first one and the reset's redraw.

Land a run's record as the data checkout's layout note says, under
`runs/sdk/sdl/<stamp>/`.

## Rereading a run's record

`nu nu/bin/nuance/sdk/controls.nu reread <record>` reads a controls run's
record again through the probe's current reader. Nothing is run and
nothing is written. Each control's checks are worked out again from the
logs and the trace saved in the record, and the probe's own record is
worked out again from the saved shim log by `sdl report`. Every check
and every count is then compared with the record's `controls.nuon`. The
command prints one NUON record and exits non-zero when anything differs
or when the reader refuses a log it once read.

The printed record names the Jab and workbench revisions that made the
capture, as `controls.nuon` gives them, apart from the revisions of the
checkouts doing the reread. Each control lists its discrepancies, empty
when it reads as recorded.

- The stripped control is left unread in one case only: its shim log
  passes the probe's own reader, `sdl log`, and the stripped QEMU
  that the log names has gone since the capture. The control is then
  marked as not reread, and the rest of the record still counts. Every
  other problem with that log fails the reread: the record holds no
  `stripped.sdl.log`; the reader refuses the log; the log names no
  executable, because its table has no object 0, object 0 is written
  `- - -`, or its path is empty or not absolute; or the log names an
  executable that was already deleted while the capture ran, its path
  ending ` (deleted)`.
- The modular control reads the system QEMU and its modules again, so it
  needs them unchanged since the capture.

Reread the set's current record whenever the reader changes in a way
that reaches what a capture holds. `sdk/just/probe.just` stands as a
shim over the bin until every consumer calls it.
