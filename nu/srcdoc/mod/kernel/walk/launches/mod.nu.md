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

A variant built in the checkout and its outputs copied out: the image,
its flags, its romfs, its demand record, its home, and the kernel built
with its symbols, whose loaded bytes (objcopy's flat image, with the
tool prefix the kernel's flags stamp ends with) are hashed; the ELF
differs build to build by the symbols its table carries.

## def wrapped

One run through walk's wrapper, its records read whole: the wrapper's
exit, its identity, the API's bytes, the guest-only reading, and the
stream as the reader reads it.

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
