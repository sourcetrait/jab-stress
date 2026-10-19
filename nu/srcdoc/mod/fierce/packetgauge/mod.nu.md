# mod.nu

PacketGauge's reading (FrameCeiling.md, FramePackets): the batteries' gauge.nuon
files under one base directory, a batch a label, a build a label less its
trailing _<n>. `settled` reads each view leg's settled frames, those after the
leg's last frame building a cell, and checks each run's capture for one L answer
a view; `play` reads every frame of each leg. Both untrimmed: per batch and leg
the least, median, 95th, and greatest of each field a run's rows hold, the
flushes and the bindings invalidated counted over every frame read, null where
any frame lacks the counter (a schema 2 run records neither), per build the mean
of its batches' medians with half their range, and every build's difference from
the first build named. Each run's cadence and identity are its own, read through
`gauge identity request`, never the report's summary unless that is the
identity's fallback. Checked first: each run complete, valid, seeded, and at the
cadence it asked, and the runs' identities' kernel, assets, route, toolchain,
cadence, and machine alike across the batches, the image apart. Its bin:
`nu/bin/nuance/fierce/packetgauge.nu <settled|play> <base> <out.nuon>
<label>...`.

## const COMMAND_L

the console's L as its answer carries it, the command's byte at 4

## def spread

Least, median, 95th, and greatest by nearest rank, null-free.

## def l-answers

The L answers a run's capture holds.

## def frames-of

A leg's frames as the mode reads them: every frame in play; in settled
the frames after the leg's last frame building a cell, none when no
frame built one.

## def held-alike

The identity's parts a comparison holds alike, the image apart.
