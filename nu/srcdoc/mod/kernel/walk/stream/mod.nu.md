# mod.nu

walk's CADENCE reader: the export a measurement build of example/walk sends over
its API after its window, read and held to the build's rules and to the build
its identity names, then, for a probed run, paired with the host's uploads.

The stream is the header, the frame records, the event records, and the end
record (example/walk/srcdoc/main.S.md). It is complete only when its header, its
end, their counts, and its CRC-32 hold; a fault there ends the reading. The
header's own faults end it as well: a rate other than 10 MHz, the one the
reader reads, so no figure is computed at another; a flag past the five a
header names; EVENT_ROOM without CADENCE_TEST; more frames than the buffer's
8,192, or more events than the header's flags' build buffers (4,096, or 52 under
EVENT_ROOM). Past them every rule is held and every fault named and counted: the
records' own fields, the frames numbered from 0 with no gap or repeat, every
frame waited, the stamps in the order their build's arm gives, each frame's raw
elapsed its start less the frame before's (the first's from the origin,
saturated at 2^32 - 1), a measured frame's dt the lesser of its raw and DT_MAX,
no final status of 2, 3, or 4, no event omitted, the events and the frames'
enters and leaves alike, the window's field the one the header's flags' build
writes (120 s, 10 s under CADENCE_TEST, 0 under REPLAY), the window's end the
build's own (a measurement's by its duration or its event room, a replay's by
its last frame) and where the build's end rules first fire, a nonce, and a
measurement's window of 60 s at least. Then the receipt stage, both readings'
before anything is computed from a receipt: each frame's flip and status
agreeing with its receipt, the present sequence one past the last from the
display's open at 1 (jab ordinal-violations), and each presented flip's
acceptance at or past its tick and inside its call, or inside its frame where
the build keeps no call's start. Then the binding, the header's capture nonce
the identity's, and the identity stage: the identity's build fields (jab's
probe build-fields, written alike by the probe and walk's wrapper) held to the
header, a measurement entering a deciding arm only through it.

`guest <run dir> <out>` reads an unprobed run from its own api.out and
identity.nuon; its record is guest-only. `<probe dir> <out>` reads a probed run
paired. `guest-runs <tree> <out dir>` reads every run of a set guest-only, its
reread's shape. `--replay <stream>` names a REPLAY run's stream where its
identity's file has moved. `replay-of <run dir> <stream>` writes a replay stream
from a run's own records, its dt values the ones the run integrated. Its bin:
`nu/bin/nuance/kernel/walk.nu`.

## const PERIOD

The kernel's tick, the clock's 10 MHz over the cap's 60.

## const HZ

The clock's ticks a second, the one rate the reader reads; PERIOD and every
figure in milliseconds stand on it.

## const SHORTEST

A measurement's least window, 60 s in ticks.

## const WINDOW

A measurement's window, 120 s in ticks, the field a measurement build writes.

## const TEST_WINDOW

A CADENCE_TEST build's window, 10 s in ticks.

## const FRAMES_MAX

walk's frame buffer, CADENCE_FRAMES, the most frames a window holds; its
filling ends a window.

## const EVENTS_MAX

The events a build buffers, EVENTS_MAX, past which an append is omitted.

## const EVENT_HEADROOM

The events a frame can add, held free before each: a window closes at the first
frame whose running count passes the build's EVENTS_MAX less this.

## const ROOM_PAST

The events an EVENT_ROOM build buffers past its headroom, 4, so its window closes
at the first frame past four.

## const DT_MAX

walk's clamp on a frame's dt, a tenth of a second.

## const RAW_MAX

The largest raw elapsed a frame stores, its u32 saturated.

## const FLAGS_PAST

A header's flags hold no bit at or past this one, the five it names being 1 to
16.

## const SYMBOLS

Each header flag's build symbol, the names the arm's faults give.

## const BUILD_FIELDS

The fields an identity names its build by. An identity naming none of them is
historical; one naming some and not all is refused.

## const HISTORICAL_UNCHECKED

What a historical reading leaves unchecked and says so: the arm and the build
against the identity, and the window's field and the events' bound held to the
header's own flags alone. Its expected flags are never taken from the header
being checked.

## const STRETCH_US

A slow stretch's least host flip interval, 1.5 periods, 25 ms.

## const STRETCH_FLIPS

The least presented flips a slow stretch holds, 5.

## const RISE

A measure's least rise over the run's steady median for a stretch to call it
risen: a quarter period, 4.17 ms, the protocol's bound for a notable change,
as the pairing's stall report takes it. The steady median, not its 95th: a run
whose isolated late frames pass a twentieth of its steady flips puts that tail
inside the 95th, and a stretch's full-period wait read against it as not risen.

## const PHASES

The guest's phases a stretch is located by: the work, the wait, and the flip
call.

## def le

A little-endian unsigned word of `size` bytes at `at`, the eight-byte
one read signed, so a value past 2^63 reads negative.

## def fault

A fault as the reading names it: the rule, how many it held, and up to
four examples.

## def faults-of

The rows that break a rule as one fault, none when no row does.

## def joined

Lists of faults joined in order.

## def crc-of

The CRC-32 of the bytes, IEEE's, through coreutils' cksum.

## def flags-of

The flags a header carries, by name.

## def window-of

The window's field a build writes, by its flags: 0 under REPLAY, 10 s under
CADENCE_TEST, else 120 s.

## def events-max

The events a build buffers, by its flags: 52 under EVENT_ROOM, else 4,096.

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

## def elapsed-faults

Each frame's raw elapsed, every run's whether measured or replayed: its start
less the frame before's, the first's its start, the origin being where
`elapsed` read the clock last, saturated at RAW_MAX. A measured run's dt, its
header declaring no REPLAY, the lesser of its raw and DT_MAX; a replay's dt is
its stream's, the identity stage's.

## def end-faults

The window's end held to the build's own end rules, applied frame by frame in
the build's order: a measurement's duration, the frame's call's end at or past
the window's field; the buffer full at its 8,192nd frame; the event room, the
running count of events past the build's buffer less its headroom. The window
must end at the first frame where one fires, by the rule that fired; a replay's
own end, its stream's frames, is the identity stage's, so a replay's window
holds only that none of the others fired before its last frame.

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

## def replay-dts

A replay stream's dt values and seed, held to its header: at least its 64
bytes, the magic WRPL, schema 1, frames 1 to 8,192, and exactly a u32 a frame
after the header.

## def replay-bound-faults

A replay run held to the stream its identity binds: the stream reopened, from
`--replay` where given, else the identity's file; its SHA-256 the identity's;
its seed the header's; its frames the window's; and each frame's dt its value,
frame for frame.

## def identity-stage

The identity's build held to the header. An identity naming no build field is
historical: valid where every other rule holds, never deciding, its unchecked
rules named. One naming them all: its CADENCE symbols holding CADENCE; the
header's TIMING, REPLAY, PREPARE, and CADENCE_TEST each set exactly where its
symbols hold them, EVENT_ROOM where its flags line defines it; its workload's
loop order `prepare` exactly where the header sets PREPARE; its image's and
kernel's SHA-256 named, carried into the reading as its build, for the
selector's matrix to hold against the declared freeze; and under REPLAY the
stream it binds (replay-bound-faults).

## def rank

The nearest-rank percentile of the values, null for none.

## def ms

Ticks in milliseconds, a null kept.

## def spread

A distribution's median and 95th in milliseconds, from ticks.

## def spread-us

A distribution's median and 95th in milliseconds, from microseconds.

## def guest-side

The guest's side of a reading (the fifth step), on a stream that held:
each frame's interval, start to start, in either arm; with TIMING the
work, the wait, and the call, each frame's own, without it unavailable,
null and never zero; the presented intervals from the receipts'
acceptances; K over them (jab k-violations, `eps` in ticks), reported
and never the run's validity; and the workload.

## def guest-of

The one path both readings take: the stream's rules but the capture's, the
receipt stage, the binding, the header's capture nonce equal to the identity's
`capture_nonce` and nonzero, and the identity stage; then the guest's side. The
record carries `historical`, `deciding` (valid and not historical), the `build`,
and the rules left `unchecked`, with the stream itself for the paired reading.

## def guest-reading

A guest-only reading (guest-of), marked guest-only, so no stretch's
attribution takes it.

## def flip-rows

Each presented flip's guest figures beside what the host's renders chose (the
selection): its frame and start; the frame interval, its start less the frame
before's; the presented interval, its acceptance less the presented flip
before's; with TIMING its work, wait, and call; its upload's interval since the
one before, its age at the render that shows it, the shown interval, and the
renders' choice.

## def flips-summary

The presented flips' host side: the renders, the flips shown, superseded,
repeated, and unshown at the end, the share shown, and the host's flip
interval, the presented interval, the age, and the shown interval.

## def against-steady

One measure of a stretch against the run's steady flips, those in no stretch:
the stretch's median, the steady median and 95th, the rise, the stretch's
median less the steady median, and risen where the rise is RISE or more.

## def stretches-of

The slow stretches: STRETCH_FLIPS or more consecutive presented flips whose
host flip interval is at least STRETCH_US. Each with its first and last frame
and ordinal, its flips, its start in seconds from the origin, its host and
presented intervals, its frame interval against the steady flips, and with
TIMING each phase against them, located by the phases risen, the work, the
wait (a late flip re-anchoring the tick, P0), or the flip call (the device or
the presentation); with none risen, delivery past the guest where the frame
interval kept its pace while the uploads spread, else the frame's rise spread
across its phases. A TIMING-off run's stretches are counted with their
intervals, no phase located.

## def paired-reading

A probed run read paired (WalkCadence's reader, steps 1 to 7): the bundle's
stream and identity through guest-of; the capture, `sdl bundle-check` with the
guest's nonce from the header (CaptureBundle's run binding, TraceBracket's trace
check), a refusal named as the capture's fault; then `sdl pair` over every
presented frame by its receipt's ordinal, the display's open its upload 1 by
position and no bracket, since only its end is recorded: TIMING on, each
flip's call's start and end (`recorded`); TIMING off, the frame's start and its
call's end (`frame`), never a call's, its long brackets named apart from the
stalls. The stages run in that order, the stream, the capture, the pairing,
and the first that fails stops the reading there, its `stage` named and what
read before it kept, the guest's side among it, the run invalid; an admitted
or ambiguous pairing is read through the selection (`nu/mod/selection`,
ProbeRuns' rules), each presented flip's figures (flip-rows), the summary,
and the slow stretches.

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

## def write

A reading's record saved as NUON.

## def show

A reading's record printed: its standing, historical or deciding, its faults
and unchecked rules, the guest's figures, the pairing's verdict and stalls, the
renders' choice, and each stretch and where it is located.

## def main

`nu/bin/nuance/kernel/walk.nu <probe dir> <out.nuon> [--eps ticks] [--replay
stream]`: a probed run read paired, saved, printed.

## def guest

`nu/bin/nuance/kernel/walk.nu guest <run dir> <out.nuon> [--eps ticks]
[--replay stream]`: an unprobed run read guest-only, saved, printed.

## def guest-runs

`nu/bin/nuance/kernel/walk.nu guest-runs <tree> <out dir> [--eps ticks]`: every
directory under a set's tree holding an api.out and an identity.nuon read
guest-only, each saved as `<name>.guest.nuon` in `out dir`, its line printed.

## def replay-of

`nu/bin/nuance/kernel/walk.nu replay-of <run dir> <stream>`: a replay stream
written from a run's own records.
