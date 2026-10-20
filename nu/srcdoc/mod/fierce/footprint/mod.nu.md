# mod.nu

FootprintEstimate's comparison of the mip level a block reads (FrameCeiling.md's
FootprintEstimate, with its fix plan's ClampedReference, SpanEndpoint, and
JudgedPopulation). `images` builds an export's debug images, each in a copy of
the export's program with its set (BUILDS), the kernel built with it and its
provenance beside it (freeze's `provenance-of`), and the 1/z floor it was
assembled with. `capture` launches a pose's kind's images (KINDS) on its map's
still copy, or a copy keeping the androids it names, under the picture
contract, binds each screen to the settled frame it shows, drawn by the serial
backend, a LEVELS frame from one packet, and asks each launch for its frames'
snapshots (CONSOLE_X); then the game's footprint crate holds the LEVELS
captures' blocks to its reference over the OWNER capture at the images' floor,
each capture's snapshot bound to its frame, and boxes where a view's two
pictures differ. `clamp-plan` plans the clamp pose's threshold and witnesses
from a capture at the release floor. `read` judges the pose set whole, every
view's blocks accounted for by class before any count, by the declared criteria
and the revised one; `crops` cuts each region where a view's pictures differ out
of both. `reread` reads a landed run again from its restoration, each pose's
disk rebuilt, its launches bound again, its reference taken anew at today's
revision, the first reading kept beside the new (EvidenceRetention's removal
gate). Its bin: `nu/bin/nuance/fierce/footprint.nu
images|capture|read|clamp-plan|crops|reread`.

## const GAME

the game's directory, jab checked out beside this repository

## const BUILDS

the images, each a label, the set it is built with, and the kind of pose it
serves: for a view, today's picture and the candidate's, the surfaces, and
today's levels and the candidate's; for the clamp, the surfaces and both
levels with IZ_TEST, the debug-only symbol that raises IZ_MIN to 5.5 m, so the
OWNER capture, both LEVELS captures, and their span tables share one floor. The
copy of the export each builds in is `<export>_<label>`.

## const KINDS

a pose's kind, `images` in its row, view unless named: its OWNER image, its
LEVELS images, today's first, and its pictures, none for the clamp

## const CONSOLE_X

the console's X: every snapshot the program holds written to the API, oldest
first (snapshot.S), sent with the E once the screen is taken, so the frame the
screen shows is among them under any cadence

## const CONSOLE_A

the console's A with its byte 4 set: every actor held at its spawn state, no
thought and no motion, its animation's first row (actor.S's `actors_held`),
JudgedPopulation's actor fixture

## const IMAGES

the images' record, in the export's own directory

## const CONSOLE_P

an API record's bytes and render.inc's REPORT_CONSOLE command byte of P

## const STAMP_AT

## const SCREEN_AT

## const SECONDS

## const BOUND_STATUS

the picture contract (workerparity.nu's): the stamp from STAMP_AT, the screen
at SCREEN_AT while the run goes on, the X and the E after it, the bound at
SECONDS so the final records land, a run the bound ends reading BOUND_STATUS

## const LAUNCH

A capture's launch condition beyond the picture contract's, recorded in its
`pose.nuon`: the API on, the sound not recorded (EvidenceRetention's drop at
the source, since nothing reads a capture's sound). A capture taken before it
recorded its sound and carries no `launch`; it keeps its own condition, and
no reader takes it under this one.

## def placement

The console's P frame with the pose's roll, which pose's pose-frame
sends as 0: the kind, three of padding, the eye's x, y, and z, then the
yaw, pitch, and roll in degrees as singles, zero to the frame's end.

## def knob-frame

## def sends-of

A launch's sends under the picture contract: the stamp and a W of the
serial backend at STAMP_AT, with a pose's `hold` the A beside them, the L
at 1900, the pose at 2000 and 8000, and the X and the E at SCREEN_AT.

## def bind

A run's screen bound to the frame it shows (`gauge measure screen-frame`):
its window opening at the frame that answered the second placement, N
at the pose sent, roll included, and drawn by the serial backend; with
`levels` N drawn from one packet besides, since a flush restarts the
span indices a LEVELS code carries. N's state as the record holds it,
the camera the reference takes.

## def footprint-tool

The game's footprint crate built release where cargo puts its targets: its
binary's path, SHA-256, the checkout's commit it was built from, and whether
the checkout held changes.

## def iz-min-of

ClampedReference's provenance rule: the floor is the integer the image was
assembled with, read from its ELF's `IZ_MIN` symbol by the toolchain's nm, never
a symbol's name or a nominal distance; 4096 on an ordinary debug build and
12,201,612 under IZ_TEST.

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
provenance.nuon beside it. The record, every image's label, set, kind,
image, kernel, digests, and IZ_MIN, goes to the export's IMAGES.

## def kept-disk

A map's copy with its androids dropped but those a pose keeps, compiled by
fierce's `tree variant` and made a romfs: a camera pose alone cannot judge an
actor on the still copy, which drops them all.

## def disk-for

A pose's disk, its map's still copy or a copy keeping its androids, made
once in `out` under a directory named for the map and the kept, and reused
by every capture into it: the digest held to the record made with it.

## def bake-of

The engine's bake from a launch's load line, `fps: lumel maps K baked in T
ms: N lumels, M unmapped`, a debug build's.

## def row-of

A launch's row: its label, status, screen and the screen's digest, its
fault lines, its bake, and its screen's binding.

## def bake-problems

The crate folds each lit surface's lumel map origin into the mapping the
reference holds a clamped block to, from its own replication of the bake;
every launch's load line must carry the same maps, lumels, and unmapped
count, so a drift in that replication refuses the pose rather than moving
its references.

## def capture

Each pose of `poses` (`--only` names some, else all), its kind's images a
launch each under the picture contract on its disk (disk-for), one disk a
map and kept set for the whole capture; the OWNER and LEVELS images held
to one IZ_MIN first. Every launch bound with no problem, status
BOUND_STATUS, and no fault line; then the reference at that IZ_MIN over the
OWNER capture and the LEVELS captures, each with its export and its bound
frame, the camera the bound LEVELS frame's state, its rows to rows.nuon;
every launch's bake held to the crate's (bake-problems); and for a view
the two pictures' differing regions. `<out>/<pose>/pose.nuon` holds the
pose, the disk, the export and its commit, the crate, the launch condition
(LAUNCH), every row, the reference, the pictures, and the problems.

## def clamp-plan

ClampedReference's plan over a pose captured at the release floor, before
the clamp's live comparison: the crate's `clamp-plan` on the OWNER and LEVELS
screens at the bound LEVELS frame's state, its threshold, its clamped
blocks, its strongest witnesses, and a derivative witness, written to
`clamp_plan.nuon` beside the pose and printed. The witness the pose set
records is the strongest.

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
derivative there; and the candidate's blocks off the declared reference
where today's agrees with it (`new_off`), its no-new-departure count.

## def verdict-of

A view's verdict by one reference, `prefix` "" the declared one and
"secant_" the secant's: outside the bands the candidate's disagreements,
sharper and coarser, at most today's, and none sharper.

## const REVISION

The revised criterion's statement, SecantCriterion's: the property it now
tests, the along term the engine's own step and the down term the
analytic derivative at the block's start on the engine's mapping, what it
leaves to AlongSpanFootprint, and the declared result standing as
recorded.

## const LIMIT

The clamp's limit, ClampedReference's: the release floor, IZ_MIN 4096, a
depth of 16,384 m, reached by no surface of the inventoried content at the
inventoried poses, so the clamp stands proved at the test threshold alone,
IZ_TEST's on the clamp pose.

## def departure-of

A view's no-new-departure check by its blocks: the candidate never off
the declared reference where today's agrees with it, and never sharper by
it where today's is not; a departure both share before the change counts
for neither.

## def population-of

JudgedPopulation's rule on a pose: every unresolved class named with its
blocks, at least one block judged, a held pose's actor blocks judged, and
a pose recording a witness its witness judged, clamped, and the candidate's
level there the clamped reference's.

## def read

The pose set's names required whole: a pose missing from `out` or refused
at capture leaves the reading incomplete, never passing on the rest. Each
view's tallies, today's and the candidate's, by the declared reference and
by the secant reference, its population (population-of), its verdict by
the criteria (verdict-of), its blocks read one by one (blocks-of), its
no-new-departure check (departure-of), and the pictures' differing pixels
and regions. A view holds only resolved; the criteria hold only when the
reading is whole and every view holds. reading.nuon holds it, the declared
criteria's whole verdict as recorded, the revised criterion's
(SecantCriterion), the secant's verdicts and no new departure on every
view together, the statement of the revision, and the clamp's limit
(LIMIT), the last two printed with the reading too.

## def restored-run

The run a restored tree came from: the `run` its restoration's receipt,
`restoration.nuon` beside the tree, names; a tree with no receipt is no
restoration's and refused.

## def restored-file

A capture's file at its path inside the run, laid in the restored tree: one
missing named, and one whose SHA-256 is not the capture's recorded digest named,
where the capture recorded one.

## def floor-of

An image's IZ_MIN: the images' record's own where it holds one, else read from
the archived ELF of the image's recorded SHA-256 in the tree's exports by its
flags' nm (iz-min-of); an images' record written before ClampedReference holds
none.

## def reread-pose

One pose read again from the restored tree into `out`. Its disk rebuilt by the
still path (disk-for) and held to the digest the capture recorded, a disk of
another digest leaving the reference unread. Each launch's screen held to its
recorded SHA-256, its stream and UART log restored; each screen bound again
(bind) and each UART's fault lines read again, every difference from the
recorded row named, the recorded row standing. The reference taken anew at
today's revision on the recorded bindings, its words as `capture` gives them,
a capture's export passed only where its recorded tally holds a snapshot: a
capture taken before the console's X carries no span table, and that limit is
named rather than filled, the crate then reading a block's end from its pixels.
The block table's SHA-256 beside the first's from the run's inventory; the
pictures differed again and held to the recorded pixels and regions. The pose's
record written as `capture` writes one, its rows' screens the restored paths,
with `reread`: the record read, the first tool, the differences, the limits, and
both tables' digests.

## def reread

A restored run read again: the run from the restoration's receipt, its
inventory, the images' record, every captured pose; the crate built
(footprint-tool); the pose set the run took written as `poses.nuon`, each pose
read again (reread-pose), then `read` over them, so the reading is today's
reader's on today's reference. Beside it the first reading, the restored `reading.nuon`,
each view's fields that changed from it named, old and new apart, neither
replacing the other. `reread.nuon` holds the run, the tool, every pose's
result, and both readings' whole verdicts. Its own outputs only: the restored
tree is read and never written.

## def crops

Each region where a pose's two pictures differ cut out of both, today's
above or left and the candidate's below or right, `pad` pixels of
context about the box held to the screen, as PNGs under
`<out>/<pose>/crops/`, any made before retired.

- each picture cropped in a list of its own, since an operator acts
  on every image of the list it meets; a wide region stacked, a tall
  one side by side
