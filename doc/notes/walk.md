# walk's cadence reader

The module `nu/mod/kernel/walk` reads the records that walk's measurement
build sends over its API at the end of a run. The build is walk built with
the `cadence` symbol, plus `timing`, `prepare`, `replay`, or `cadence_test`
for its variants. walk's own source documentation describes the records
byte by byte, in `example/walk/srcdoc/main.S.md` of the Jab checkout.

Its commands are its bins, run under the real nu:

| Command | What it does |
|---|---|
| `nu nu/bin/nuance/kernel/walk.nu <probe dir> <out.nuon>` | Reads a probed run: the program's records, the bundle's check, the pairing with the host's uploads, and the slow stretches |
| `nu nu/bin/nuance/kernel/walk.nu guest <run dir> <out.nuon>` | Reads a run that was not probed, from its own `api.out` and `identity.nuon` |
| `nu nu/bin/nuance/kernel/walk.nu guest-runs <tree> <out dir>` | Reads every run under a set's directory the way `guest` reads one, a reading file for each |
| `nu nu/bin/nuance/kernel/walk.nu replay-of <run dir> <stream>` | Writes a replay stream from a run's records, for a replay build to repeat its workload |
| `nu nu/bin/nuance/kernel/walk/launches.nu <jab checkout> <scratch>` | Builds walk's test variants, runs each through walk's wrapper, and holds what each run must show |
| `nu nu/bin/nuance/kernel/walk/launches.nu reread <tree> <out.nuon>` | Reads a landed launches run's recorded cases again, launching nothing, and holds each as its launch did |

The two readers take `--replay <stream>` for a replay run whose stream
has moved since the run.

## walk's own launches

`nu/mod/kernel/walk/launches` is walk's fixture for its measurement build.
It builds walk six ways with `cadence_test`, which shortens the window
to ten seconds and adds a quiet stretch, a stall, and one long frame. It
copies each build out before the next, since a build replaces the last
one's image. Four runs cover walk's two loop orders with the phase
stamps on and off. One run closes its window by the event room, and one
replays the await order's stamped run. Four more runs end by the
bounded waits: no nonce, a nonce cut short, no replay stream, and a
replay header cut short. Each run but the last four goes through walk's
wrapper, `example/walk/test/cadence.nu` in the Jab checkout, and the
reader reads it. The checkout is reached through its own bins, never its
modules: its builds through `nu/bin/do.nu`, their target through
`nu/bin/nuance/plan.nu`, and the last four runs through
`nu/bin/nuance/launch.nu`, their nonce frame written in the fixture. It
takes about two minutes and must run alone on the machine. Each run boots
the kernel its own build made: the symbols land in the kernel's symbol
table, so the kernel files differ, while the bytes they load must match,
which the script checks.

## What a reading checks

A run's records are refused unless they arrive whole. The header, the
end record, their counts, and the CRC-32 over the records must all
agree, and the reader stops at the first of those that fails. The
header must also declare the clock's rate of 10 MHz, which is the only
rate the reader computes with. Its flags must be ones a header can
carry, and the event room only in a test build. Its counts must fit the
build's buffers, 8,192 frames and 4,096 events, or 52 events for the
event room's build.

After that it checks every rule and names every fault it finds, with a
count and up to four examples. The frames must be numbered from 0 with no
gap or repeat. Every frame must have waited for its presentation. The
stamps must follow the order of the build's loop. Each frame's raw
elapsed time must be its start less the start of the frame before, and a
measured frame's dt must be that time held to a tenth of a second. No
frame may end with a failed flip. No event may be missing. The header's
window must be the one its build writes: 120 seconds, 10 for a test
build, and none for a replay. The window must end where the build's own
rules end it, at the first frame that reaches the window's end, fills the
frame buffer, or runs out of event room. A measurement window must run at
least 60 seconds. The capture nonce must be set.

The receipt stage comes next, before anything is computed from a flip's
receipt. Each frame's flip must agree with its status. The present
ordinals must rise by one for each presented flip, starting from the
display's open at 1. Each presented flip must be accepted at or after
its tick, and inside its own call.

Then the run's identity. The nonce in the records' header must match the
run's identity. The identity names the build the run came from: the
image and the kernel by their SHA-256, the build's flags, the
measurement symbols among them, and the loop order. Jab's probe and
walk's wrapper write these the same way. The header's symbols must be
the identity's, and the loop order must agree. A replay run must match
the replay stream its identity names, its frames and every dt. A run whose
identity names no build is read as historical: its other rules are
checked, the rules that need the build are named unchecked, and it never
counts as deciding. Only a valid reading with a build is deciding.

A reading of a run that was not probed is marked guest-only. It reports
the guest's own intervals and phases, and nothing about what the host's
window showed.

## The paired reading

A probed run is read in three stages: its records as above, its bundle's
check, and the pairing. The first stage that fails stops the reading,
and the reading names that stage and keeps what it read before it.

The pairing matches each presented flip to the upload the host logged
for it, by its ordinal. It holds every upload inside its flip's call
when the build records the call. A build without the phase stamps
records only the frame around the call, so its uploads are held inside
their frames, which is a weaker check, and the reading says so. A long
call is reported as a stall and never refuses a run.

With the pairing read, each presented flip gets the host's side: the time
since the upload before, whether a window render showed it, superseded
it, or repeated it, and how long it waited to be shown. These are the
same rules the probed fps runs are read by, in `nu/mod/selection`.

A slow stretch is five or more presented flips in a row that reached
the host 25 milliseconds or more apart. Each stretch is set against the
same run's steady flips, those outside every stretch. A phase of the
guest's frame has risen when its median in the stretch passes the
steady flips' median by a quarter of a period, 4.17 milliseconds. The
reading names the work, the wait, or the flip call that rose. A risen
wait is a late flip moving the next tick a period on. When no phase
rose and the guest's frames kept their pace while the uploads spread,
it names delivery past the guest. When the frames slowed with no one
phase rising that far, it says the rise was spread across the phases.
A run without the phase stamps reports its stretches with their
intervals and names no phase.

Every reading states its limits. The guest's clock measures elapsed
time, so a host stall inside a phase reads as that phase. The pairing
gives intervals, not the absolute delay from the guest to the window.
A stretch is judged only against its own run.

## What the reader needs

It needs GNU coreutils' `cksum` with `-a crc32b` (coreutils 9.6 or
later) for the CRC-32, and the Jab checkout beside this repository.
