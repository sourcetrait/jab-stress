# mod.nu

FootprintEstimate's comparison of the mip level a block reads (FrameCeiling.md's
FootprintEstimate). `images` builds five debug images of one export, each in a
copy of the export's program with its set (BUILDS): today's picture and the
candidate's, debug and debug with FOOTPRINT; the surfaces, debug with OWNER; and
today's levels and the candidate's, debug with LEVELS and with LEVELS and
FOOTPRINT; beside each the kernel built with it and its provenance (freeze's
`provenance-of`). `capture` launches every image at each pose of a pose set on
its map's still copy under the picture contract, binds each screen to the
settled frame it shows, drawn by the serial backend, a LEVELS frame from one
packet; then the game's footprint crate holds both LEVELS captures' blocks to
the reference over the OWNER capture (`reference`) and boxes where the two
pictures differ (`differ`). `read` judges the references by the declared
criteria, with the secant reference beside them, and lists the pictures'
regions; `crops` cuts each region out of both pictures side by side for reading.
Its bin: `nu/bin/nuance/fierce/footprint.nu images|capture|read|crops`.

## const GAME

the game's directory, jab checked out beside this repository

## const BUILDS

the images: today's picture and the candidate's, the surfaces, and
today's levels and the candidate's, each a label and the set it is built
with; the copy of the export it builds in is `<export>_<label>`

## const IMAGES

the images' record, in the export's own directory

## const CONSOLE_P

an API record's bytes and render.inc's REPORT_CONSOLE command byte of P

## const STAMP_AT

the picture contract (workerparity.nu's): the stamp from STAMP_AT, the
screen at SCREEN_AT while the run goes on, the E after it, the bound at
SECONDS so the final records land, a run the bound ends reading
BOUND_STATUS

## def placement

The console's P frame with the pose's roll, which pose's pose-frame
sends as 0: the kind, three of padding, the eye's x, y, and z, then the
yaw, pitch, and roll in degrees as singles, zero to the frame's end.

## def sends-of

A launch's sends under the picture contract: the stamp and a W of the
serial backend at STAMP_AT, the L at 1900, the pose at 2000 and 8000,
and the E at SCREEN_AT.

## def bind

A run's screen bound to the frame it shows (`gauge measure screen-frame`):
its window opening at the frame that answered the second placement, N
at the pose sent, roll included, and drawn by the serial backend; with
`levels` N drawn from one packet besides, since a flush restarts the
span indices a LEVELS code carries. N's state as the record holds it,
the camera the reference takes.

## def footprint-tool

The game's footprint crate built where cargo puts its targets: its
binary's path, SHA-256, and the checkout's commit it was built from.

## def program-of

The export's program directory, the one holding a manifest.

## def images

The images of an export (BUILDS), each its program copied beside the
export as `<export>_<label>`, its src/, manifest, and source.nuon, the
manifest still naming the export's SDK and the checkout's workspace;
the checkout's kernel and then the copy built debug with its set by the
checkout's tool; its flags holding DEBUG and every symbol of its set;
that kernel copied beside it as `kernel.elf` with its loaded bytes,
objcopy's flat image, as `kernel.bin`, every image's the same; and
provenance.nuon beside it. The record, every image's label, set, image,
kernel, and digests, goes to the export's IMAGES.

## def disk-for

A map's still disk for a capture, made once in `out` and reused by every
capture into it: the digest held to the record made with it.

## def row-of

A launch's row: its label, status, screen and the screen's digest, its
fault lines, and its screen's binding.

## def capture

Each pose of `poses` (`--only` names some, else all), every image of
the export (IMAGES) a launch under the picture contract on the pose's
map's still copy, one disk a map for the whole capture (disk-for); every
launch bound with no problem, status BOUND_STATUS, and no fault line; then
the reference over the OWNER capture and the two LEVELS captures, the
camera the bound LEVELS frame's state, its rows to rows.nuon; and the two
pictures' differing regions. `<out>/<pose>/pose.nuon` holds the pose,
the disk, every row, the reference, the pictures, and the problems.

## def judged

A level's verdict against a reference level and its band, as the
crate's judge gives it: within the band either level beside its
boundary agrees.

## def blocks-of

A pose's judged blocks (rows.nuon) read block by block: by the declared
reference, the candidate's sharper blocks today's are not (its own) and
those both are; and each estimator's blocks the declared reference
judges off and the secant reference passes, the along-span step's,
since the two references differ in that term alone, with how many of
them the along term decides and the block's step over the start's
derivative there.

## def verdict-of

A view's verdict by one reference, `prefix` "" the declared one and
"secant_" the secant's: outside the bands the candidate's disagreements,
sharper and coarser, at most today's, and none sharper.

## def read

Every pose captured into `out` judged: each view's tallies, today's and
the candidate's, by the declared reference and by the secant reference,
each view's verdict by the criteria (verdict-of), its blocks read one by
one (blocks-of), and the pictures' differing pixels and regions; a pose
refused at capture listed apart. reading.nuon holds it, and both
criteria's whole verdicts.

## def crops

Each region where a pose's two pictures differ cut out of both, today's
above or left and the candidate's below or right, `pad` pixels of
context about the box held to the screen, as PNGs under
`<out>/<pose>/crops/`, any made before retired.

- each picture cropped in a list of its own, since an operator acts
  on every image of the list it meets; a wide region stacked, a tall
  one side by side
