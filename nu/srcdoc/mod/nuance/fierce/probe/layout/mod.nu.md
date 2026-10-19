# mod.nu

TileLayout's LayoutProbe candidates: jab's kit/fierce `src` at a commit copied
to <cands>/layout_<case>_<commit> beside a candidate's manifest, the checkout's
SDK by absolute path, the layout's edits applied to render.inc, raster.S,
tile.S, main.S, and world.S, each find matched exactly once. A case is a layout
and a class setting: rows, blocks (four-by-four squares of texels in row order),
or Morton (the index's twelve bits interleaved), under the walls alone or the
walls with the planes; the count cases are the planes' for `--set debug,count`,
a COUNT build landing in a tree of its own. The layouts other than rows address
a texel by dilated coordinates: u and v each hold their bits below the texel
beside their texel's bits spread to the axis's places in the index, a pixel's
step adds across the holes filled, and the texel is (U | V) shifted down to its
bytes. Rows assembles span_fill's and tile_build's code as the commit has it;
COUNT's tile counters count a tiled block's reads and the 64-byte lines they
enter by class. Its bin, `nu/bin/nuance/fierce/probe/layout.nu <cands> <commit>
[case...]`, runs it.

## def main

- ours only: a candidate tree of this name, its src replaced
