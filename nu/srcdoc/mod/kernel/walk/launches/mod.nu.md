# mod.nu

walk's own CADENCE_TEST launches (WalkCadence): the measurement build made its
own fixture, each run read by the reader's guest-only path with its test's
admission. Each build is made in the Jab checkout and copied out with its flags,
its romfs, its demand record, its home, and its kernel before the next, since
every build of a symbol set lands in its tree's one output; the kernels, which
read none of the symbols, are held to load the same bytes, their ELFs differing
by the symbols their tables carry, and each run boots its own build's. walk's
wrapper, example/walk/test/cadence.nu, runs each loop order with TIMING on and
off on 1KA1, the event room's close, and a replay of the await order's TIMING
run with frame 331's clamp among its frames; the bounded waits' four exits go
through jab launch with frames of their own. A case's failure is raised with its
name. Alone on the box, about two minutes. Its bin:
`nu/bin/nuance/kernel/walk/launches.nu <jab_dir> <scratch> [--only <cases>]`.

The checkout `jab_dir` is reached through its own bins alone, never by
importing its modules, whose paths a parse fixes to one checkout: its builds
through `nu/bin/do.nu`, their target through `nu/bin/nuance/plan.nu`, the runs
through walk's wrapper, and the exits through `nu/bin/nuance/launch.nu`, its
record read back as NUON.

## const NONCE_FRAME

The capture nonce 77's WNON frame as the protocol defines it, the magic
`WNON`, four zero bytes, and the nonce's eight bytes little endian, written
here rather than taken from the SDK, so an exit's bytes stand apart from the
code under test.

## const EXITS

the exits and the frames each sends (exit-bytes): none, a nonce cut to
its first 8 bytes, a nonce alone before a replay build's stream, and a
nonce before a replay header cut at 32 of its 64 bytes

## def main

Each case run against the Jab checkout `jab_dir`, the builds made there, in
`scratch`, a directory the call makes, its builds and runs under it; `--only`
the cases to run, comma separated, every one unless given, a replay
bringing its reference and an exit a run to time it by.

- each loop order with TIMING on and off
- the event room: the first frame past four events closes the window, nothing omitted
- a replay of the await order's TIMING run, its workload frame for frame
- the bounded waits' exits, inside the wait plus a second past reaching it

## def exit-bytes

An exit case's frame: none, the nonce's frame cut to its first 8 bytes,
the frame whole, or the frame whole before a replay header's first 32
bytes, its magic, schema 1, and 16 frames then zeros.

## def build-variant

A variant built by the checkout's driver and its outputs copied out from
the target its planner names (`plan.nu`'s `target`, its machine planned
under the variant's `plan/`): the image, its flags, its romfs, its demand
record, its home, and the kernel built with its symbols, whose loaded
bytes (objcopy's flat image, with the tool prefix the kernel's flags
stamp ends with) are hashed; the ELF differs build to build by the
symbols its table carries.

## def wrapped

One run through walk's wrapper, its exit held, then its records read
(recorded).

## def recorded

A run's records read whole: its identity, the API's bytes, the guest-only
reading with its test's admission, raised by name unless valid, a replay
read against the stream `replay` names, and the stream as the reader reads
it.

## def reread

`nu/bin/nuance/kernel/walk/launches.nu reread <tree> <out.nuon>`: a landed
launches run's recorded cases read again by today's reader, nothing
launched, each held as its launch held it: the loop-order runs present
under `tree/runs/` by four-holds, the event room by room-holds, and the
replay against the await order's TIMING run and the stream beside them,
`await_on.wrpl`, by replay-holds. The exit cases hold no stream; their
holds are their launches', named unread. The record of what each held,
with its reading, saved to `out`; a case's failure raised by name.

## def intervals

Each frame's start to the next's, for the frames first to last.

## def four-holds

What the four launches hold beside their readings' validity, which
holds the stream, the receipt stage, the binding, and the arm's stamps.

## def room-holds

The event room's close: ended by it, nothing omitted, at the first
frame whose events passed four, the buffer's room past the headroom.

## def replay-holds

The replay: ended by its last frame, its frames the reference's count,
its workload the reference's frame for frame, its dt the reference's,
frame 331's clamp among them.
