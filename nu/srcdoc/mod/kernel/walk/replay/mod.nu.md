# mod.nu

A replay stream: read and held to its header, bound to a REPLAY run's
identity, written from a run's own records, and a replay's workload held to
its reference (walk's replay).

## def replay-dts

A replay stream's dt values and seed, held to its header: at least its 64
bytes, the magic WRPL, schema 1, frames 1 to 8,192, and exactly a u32 a frame
after the header.

## def replay-bound-faults

A replay run held to the stream its identity binds: the stream reopened, from
`--replay` where given, else the identity's file; its SHA-256 the identity's;
its seed the header's; its frames the window's; and each frame's dt its value,
frame for frame.

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
