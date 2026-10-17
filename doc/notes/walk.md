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
