# walk's cadence reader

`kernel/walk/cadence.nu` reads the records that walk's measurement build
sends over its API at the end of a run. The build is walk built with the
`cadence` symbol, plus `timing`, `prepare`, `replay`, or `cadence_test`
for its variants. walk's own source documentation describes the records
byte by byte, in `example/walk/srcdoc/main.S.md` of the Jab checkout.

The recipes are in `kernel/just/walk.just` and run under the real nu:

| Recipe | What it does |
|---|---|
| `just -f kernel/just/walk.just cadence <probe dir> <out.nuon>` | Reads a probed run: its bundle is checked first, then the program's records inside it |
| `just -f kernel/just/walk.just guest <run dir> <out.nuon>` | Reads a run that was not probed, from its own `api.out` and `identity.nuon` |
| `just -f kernel/just/walk.just replay-of <run dir> <stream>` | Writes a replay stream from a run's records, for a replay build to repeat its workload |
| `just -f kernel/just/walk.just cadence-holds <script> <scratch>` | Runs the reader's own fixtures, the script named so that a mutant's copy can run in its place |
| `just -f kernel/just/walk.just cadence-launches <jab checkout> <scratch>` | Builds walk's test variants, runs each through walk's wrapper, and holds what each run must show |
| `just -f kernel/just/walk.just cadence-mutants <jab checkout> <set> <scratch>` | Runs walk's mutant set, each mutant expected to fail at its own case |

## walk's own launches

`kernel/walk/launches.nu` is walk's fixture for its measurement build.
It builds walk six ways with `cadence_test`, which shortens the window
to ten seconds and adds a quiet stretch, a stall, and one long frame. It
copies each build out before the next, since a build replaces the last
one's image. Four runs cover walk's two loop orders with the phase
stamps on and off. One run closes its window by the event room, and one
replays the await order's stamped run. Four more runs end by the
bounded waits: no nonce, a nonce cut short, no replay stream, and a
replay header cut short. Each run but the last four goes through walk's
wrapper, `example/walk/test/cadence.nu` in the Jab checkout, and the
reader reads it. It takes about two minutes and must run alone on the
machine. Each run boots the kernel its own build made: the symbols land
in the kernel's symbol table, so the kernel files differ, while the
bytes they load must match, which the script checks.

## walk's mutants

`kernel/walk/mutants.nu` runs walk's mutant set, `walk_mutants.nuon`
under `assets/kernel/mutants/` in the data repository. A reader mutant
changes a copy of `cadence.nu` and runs that copy's fixtures. A program
mutant changes walk's source in the Jab checkout, runs the launches its
cases name, and puts the source back as the checkout's last commit has
it; the file must match that commit before the mutant is written. A
control runs first for each kind. A mutant is caught when its run fails
with its expected case named in the failure.

## What a reading checks

A run's records are refused unless they arrive whole. The header, the
end record, their counts, and the CRC-32 over the records must all
agree, and the reader stops at the first of those that fails. After
that it checks every rule and names every fault it finds, with a count
and up to four examples. The frames must be numbered from 0 with no gap
or repeat. Every frame must have waited for its presentation. The stamps
must follow the order of the build's loop. No frame may end with a
failed flip. No event may be missing. The window must end the way the
build ends it, and a measurement window must run at least 60 seconds.
The capture nonce must be set.

The receipt stage comes next, before anything is computed from a flip's
receipt. Each frame's flip must agree with its status. The present
ordinals must rise by one for each presented flip, starting from the
display's open at 1. Each presented flip must be accepted at or after
its tick, and inside its own call.

A reading of a run that was not probed is marked guest-only. Its records
are tied to the run by the nonce in their header, which must match the
run's identity. Such a reading reports the guest's own intervals and
phases, and nothing about what the host's window showed.

## What it does not read yet

The pairing of a probed run's flips with the host's uploads is not read
yet, so neither are the host-side intervals or the slow stretches. A
probed reading says so in its `pending` field.

## What the reader needs

It needs GNU coreutils' `cksum` with `-a crc32b` (coreutils 9.6 or
later) for the CRC-32, and the Jab checkout beside this repository.
