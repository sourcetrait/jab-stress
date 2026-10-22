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

This module holds the bin's verbs, each reading saved and printed; the
reader's parts lie in its children, each importing its siblings by path and
none importing this module, and the workbench's own modules import the child
they need. `stream` reads the export's records and holds them to the stream's
rules (stream-of), the faults' vocabulary every part names its faults in
beside it; `replay` reads a replay stream, binds it to a REPLAY run, writes
one from a run's records, and holds a replay's workload to its reference;
`reading` holds the receipt stage and the identity stage and takes the
guest's side, a guest-only reading (guest-reading); `paired` reads a probed
run paired (paired-reading); `launches` and `controls` are walk's own
fixtures.

## def write

A reading's record saved as NUON.

## def show

A reading's record printed: its standing, historical or deciding, its faults
and unchecked rules, a reading that did not stand its contract, its K or why
it is unavailable, the guest's figures, the pairing's verdict and stalls, the
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
