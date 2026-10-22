# mod.nu

walk's CADENCE stream read from its bytes and held to its rules, and the
faults every part of the reading names (walk's stream).

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

## def header-nonce

The header's capture nonce from an export's bytes, what a paired
bundle's check takes as the guest's echo; null for a stream too short
to hold its header.
