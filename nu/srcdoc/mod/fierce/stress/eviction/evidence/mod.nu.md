# mod.nu

A picture's evidence and a dump's: a frame settled, the window a picture's stamp
must name a frame of, a picture's refusals in prerequisite order, a capture's
stamp written over, a capture's dumps keyed through jab's tiles bin in a nu of
its own, and a dumped tile's rows read from its capture.

## const RECORD

the API's records, a dump header's kind and its texel records a tile
(tiles' DUMP_KIND and DUMP_RECORDS, twelve texels a record from its
byte 12), and a header's state of a tile in construction

## def dump-keys

A capture's dumps keyed through the tiles bin in a nu of its own: each
dump's tiles by their headers and texel hashes, and the problems.

## def settled

A frame settled: no block drawn without its tile, no tile in
construction, nothing admitted, dropped, filtered, or built.

## def unsettled-fields

A frame's settling fields that are not zero, named with the frame.

## def capture-of

A launch's screen held whole, or null when it took none.

## def stamp-written

A capture with its stamp's cells written as hud.S writes a frame's:
the low STAMP_BITS bits of `value`, a cell of STAMP_CELL pixels square a
bit along the top-left, the n-th from the left the n-th bit, STAMP_ONE a
one and STAMP_ZERO a zero.

## def picture-window

The window a picture's stamp must name a frame of, read from a complete
measurement: from the frame after the last that published at `from` or
later, before the end marker's.

## def displayed-frame

The frame of the window whose number the stamp holds, null when none.

## def picture-refusals

A picture's refusals, each a kind, its detail, and the frames it
names, in prerequisite order, a refusal ending the checks that need what
it refuses. `e` is a launch's evidence: its `measure`, its `capture`
(null when it took none), `from` (the window's first frame: a phase's,
or the frame after a recorded placement), `published` (a publication
from `from` required; none when absent), and the screen's `completed`
and E's `ended`, seconds from the start (null when unrecorded). The
measurement incomplete, else invalid; the capture absent, else its stamp
unreadable; with both usable, nothing published from `from` when one is
required, else the stamp naming no frame f with last_build + 1 <= f <
final (picture-window), else each frame from last_build + 1 through the
displayed one unsettled; and
whatever those hold, the screen's completion or E's write unrecorded,
else E written at or before the screen completed. Empty when the
picture is bound.

## def tile-rows

A dumped tile's texels as its TILE_SIDE rows of bytes, read from the
capture's records: the one dump header naming the tile's slot, key, and
frame, then its DUMP_RECORDS texel records, twelve texels a record. The
capture's dumps are read whole first (dump-keys), so a header's records
follow it unbroken.

## def pixels-differ

The pixels of row `y` over which two captures differ, at most `most`,
each as [x, y].
