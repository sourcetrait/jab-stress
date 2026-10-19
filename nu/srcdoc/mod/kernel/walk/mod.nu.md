# mod.nu

walk's CADENCE reader: the export a measurement build of example/walk sends over
its API after its window, read and held to the build's rules.

The stream is the header, the frame records, the event records, and the end
record (example/walk/srcdoc/main.S.md). It is complete only when its header, its
end, their counts, and its CRC-32 hold; a fault there ends the reading. Past
them every rule is held and every fault named and counted: the records' own
fields, the frames numbered from 0 with no gap or repeat, every frame waited,
the stamps in the order their build's arm gives, no final status of 2, 3, or 4,
no event omitted, the events and the frames' enters and leaves alike, the
window's end the build's own (a measurement's by its duration or its event room,
a replay's by its last frame), a nonce, and a measurement's window of 60 s at
least. Then the receipt stage, both readings' before anything is computed from a
receipt: each frame's flip and status agreeing with its receipt, the present
sequence one past the last from the display's open at 1 (jab
ordinal-violations), and each presented flip's acceptance at or past its tick
and inside its call, or inside its frame where the build keeps no call's start.

`guest <run dir> <out>` reads an unprobed run from its own api.out and
identity.nuon, its binding the header's nonce, the identity's capture_nonce, and
nothing of its presents; its record is guest-only. `<probe dir> <out>` reads a
probed run's bundle: the bundle checked (jab sdl-bundle-check), the program's
own nonce read from its api.out, then the same reading of the guest's side; the
pairing with the host's uploads is not read yet, the reading saying so.
`replay-of <run dir> <stream>` writes a replay stream from a run's own records,
its dt values the ones the run integrated. Its bin:
`nu/bin/nuance/kernel/walk.nu`, with `guest` and `replay-of`.

## const PERIOD

the kernel's tick, the clock's 10 MHz over the cap's 60

## const SHORTEST

a measurement's least window, 60 s in ticks

## def le

A little-endian unsigned word of `size` bytes at `at`, the eight-byte
one read signed, so a value past 2^63 reads negative.

## def fault

A fault as the reading names it: the rule, how many it held, and up to
four examples.

## def faults-of

The rows that break a rule as one fault, none when no row does.

## def crc-of

The CRC-32 of the bytes, IEEE's, through coreutils' cksum.

## def flags-of

The flags a header carries, by name.

## def stream-of

The stream read whole and held to its rules (the reading's first step).
A fault in its header, its length, its end record, their counts, or its
CRC ends the reading there; past them the records are read and every
rule held, each fault named and counted. `test` admits a CADENCE_TEST
build, whose window its own test reads; a measurement takes no test
build. `complete` when no fault ends the reading, the faults beside it.

## def zeroed

Whether every byte is zero.

## def phase-faults

A TIMING build's frames out of their phase order: walk's, the wait's
start, its end, the frame's start, the work's end, the call's start, its
end; PREPARE's, the frame's start, the work's end, the wait's start, its
end, the call's start, its end; and each frame's start at or past the
frame before's call's end.

## def untimed-faults

A build without TIMING: its four fields zero, and each frame's start at
or before its call's end, that end at or before the next frame's start.

## def receipt-faults

The receipt stage, every reading's before anything is computed from a
receipt: a frame with no flip issued carries NO_STATUS, s 0, and T 0,
and one with a flip issued a status, s and T nonzero with a 0 or a 1, a
2 to 4 being the stream's own refusals; the
present sequence from the display's open at 1 (jab
ordinal-violations), a presented flip one past the last and every other
frame the last, a failed present's 3 taken as presented where its
ordinal moved on by one, since its flush can be acknowledged after a
refused transfer; and each presented flip's s at or past its T and inside
its call, the call's start and end with TIMING, the frame's start and
the call's end without it. Every fault named and counted.

## def rank

The nearest-rank percentile of the values, null for none.

## def spread

A distribution's median and 95th in milliseconds, from ticks.

## def guest-side

The guest's side of a reading (the fifth step), on a stream that held:
each frame's interval, start to start, in either arm; with TIMING the
work, the wait, and the call, each frame's own, without it unavailable,
null and never zero; the presented intervals from the receipts'
acceptances; K over them (jab k-violations, `eps` in ticks), reported
and never the run's validity; and the workload.

## def guest-reading

A guest-only reading: the stream's rules but the capture's, the receipt
stage, and the binding, the header's capture nonce equal to the
identity's `capture_nonce` and nonzero; then the guest's side. Marked
guest-only, so no stretch's attribution takes it.

## def header-nonce

The header's capture nonce from an export's bytes, what a paired
bundle's check takes as the guest's echo; null for a stream too short
to hold its header.

## def replay-stream

A replay stream from a run's own records, which must read complete and
valid: the header, WRPL, schema 1, the frames, the run's seed, and the
SHA-256 of the run's export, then each frame's dt, the value the run
integrated, never its raw elapsed.

## def replay-faults

A replay run's workload held to its reference's frame for frame, the
walkers, the rectangles and their area, the drawn area, the enters, and
the leaves; every difference a fault, and a count other than the
reference's one.

## def stretches-of

A stretch's attribution takes a paired reading alone: a guest-only
record has no host side to locate a stretch in.
