# mod.nu

A probed run read paired: the bundle checked, the pairing with the host's
uploads, the renders' choice, and the slow stretches (walk's paired).

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
