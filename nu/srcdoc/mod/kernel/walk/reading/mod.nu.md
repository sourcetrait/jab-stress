# mod.nu

The guest's reading of a stream: the receipt stage, the identity stage, the
guest's side, and a guest-only reading (walk's reading).

## const PERIOD

The kernel's tick, the clock's 10 MHz over the cap's 60.

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
