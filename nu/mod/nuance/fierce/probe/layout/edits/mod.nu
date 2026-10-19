# render.inc's tile classes setting, as the commit has it
const SETTINGS_FIND = r#'.set TILE_CLASSES, TILE_CLASS_WALLS
'#

# The classes and the layout set, with the layout's places checked
const SETTINGS_PUT = r#'.set TILE_CLASSES, @CLASSES@
# A texel's place in its tile: rows, or its index's twelve bits placed by
# axis, u's at TILE_PLACE_U and v's at TILE_PLACE_V.
.set LAYOUT_ROWS, 0
.set LAYOUT_BLOCKS, 1
.set LAYOUT_MORTON, 2
.set TILE_LAYOUT, @LAYOUT@
.if TILE_LAYOUT == LAYOUT_BLOCKS
.set TILE_PLACE_U, 0x0f3
.set TILE_PLACE_V, 0xf0c
.elseif TILE_LAYOUT == LAYOUT_MORTON
.set TILE_PLACE_U, 0x555
.set TILE_PLACE_V, 0xaaa
.endif
.if TILE_LAYOUT != LAYOUT_ROWS
.if ((TILE_PLACE_U & TILE_PLACE_V) != 0) || ((TILE_PLACE_U | TILE_PLACE_V) != ((1 << (2 * TILE_SHIFT)) - 1))
.error "a layout places each of a texel's index bits once"
.endif
.endif
'#

# render.inc's COUNT fields' end, as the commit has it
const COUNT_FIELDS_FIND = r#'.set COUNT_REENTRY_CUT, 80
.set COUNT_SIZE, 88
'#

# The COUNT fields with the tiled reads and lines by class
const COUNT_FIELDS_PUT = r#'.set COUNT_REENTRY_CUT, 80
.set COUNT_TILE_READS_PLANES, 88
.set COUNT_TILE_READS_WALLS, 96
.set COUNT_TILE_LINES_PLANES, 104
.set COUNT_TILE_LINES_WALLS, 112
.set COUNT_SIZE, 120
'#

# raster.S's count_add macro, as the commit has it
const COUNT_MACRO_FIND = r#'.ifdef COUNT
.macro count_add field, scratch, base, n=1
    addi \base, tp, CTX_COUNT
    ld \scratch, \field(\base)
    addi \scratch, \scratch, \n
    sd \scratch, \field(\base)
.endm
.endif
'#

# count_add with count_tile, a tiled read and its line counted by class
const COUNT_MACRO_PUT = r#'.ifdef COUNT
.macro count_add field, scratch, base, n=1
    addi \base, tp, CTX_COUNT
    ld \scratch, \field(\base)
    addi \scratch, \scratch, \n
    sd \scratch, \field(\base)
.endm

# A tiled read counted by its surface's class, and the 64-byte line it
# enters where that differs from the line of the block's read before it,
# held in s5, -1 at a tiled block's start: a5 the read's address, a6 and
# a7 its scratch.
.macro count_tile
    ld a6, CTX_COMMAND(tp)
    ld a6, POLY_SURFACE(a6)
    li a7, LUMAP_PLANES
    bltu a6, a7, .Lcount_tile_plane\@
    count_add COUNT_TILE_READS_WALLS, a6, a7
    srli a6, a5, 6
    beq a6, s5, .Lcount_tile_end\@
    mv s5, a6
    count_add COUNT_TILE_LINES_WALLS, a6, a7
    j .Lcount_tile_end\@
.Lcount_tile_plane\@:
    count_add COUNT_TILE_READS_PLANES, a6, a7
    srli a6, a5, 6
    beq a6, s5, .Lcount_tile_end\@
    mv s5, a6
    count_add COUNT_TILE_LINES_PLANES, a6, a7
.Lcount_tile_end\@:
.endm
.endif
'#

# raster.S's span setup, as the commit has it
const SETUP_FIND = r#'    li t4, 0
    sd s5, 40(sp)
    mv t2, s11
    ld a6, 16(sp)
    andi a6, a6, POLY_MASKED
    bnez a6, 85f
'#

# The span setup with the dilated coordinates and their masks
const SETUP_PUT = r#'    li t4, 0
    sd s5, 40(sp)
.ifdef COUNT
    li s5, -1                       # no line read yet in the block
.endif
.if TILE_LAYOUT != LAYOUT_ROWS
    li a7, -1
    sll a7, a7, s0
    not a7, a7                      # F, a coordinate's bits below its texel
    addi a6, s0, 2                  # an index's bit 0 in the field, a texel 4 bytes
    li a3, TILE_PLACE_U
    sll a3, a3, a6
    or a3, a3, a7                   # M_u, u's bits in the field
    not a2, a3                      # H_u, its holes, filled so a carry crosses them
    li t3, TILE_PLACE_V
    sll t3, t3, a6
    or t3, t3, a7                   # M_v
    not a4, t3                      # H_v
    la a0, tile_spread
    srl a5, s8, s0
    andi a5, a5, (TILE_SIDE - 1)
    sh1add a5, a5, a0
    lhu a5, 0(a5)
    sll a5, a5, a6
    and s8, s8, a7
    or s8, s8, a5                   # U, u's fraction beside its texel spread
    srl a5, s9, s0
    andi a5, a5, (TILE_SIDE - 1)
    sh1add a5, a5, a0
    lhu a5, (TILE_SIDE * 2)(a5)
    sll a5, a5, a6
    and s9, s9, a7
    or s9, s9, a5                   # V
    sra a5, t5, s0
    andi a5, a5, (TILE_SIDE - 1)
    sh1add a5, a5, a0
    lhu a5, 0(a5)
    sll a5, a5, a6
    and t5, t5, a7
    or t5, t5, a5                   # dU, a negative step wrapping in the field
    sra a5, t6, s0
    andi a5, a5, (TILE_SIDE - 1)
    sh1add a5, a5, a0
    lhu a5, (TILE_SIDE * 2)(a5)
    sll a5, a5, a6
    and t6, t6, a7
    or t6, t6, a5                   # dV
.endif
    mv t2, s11
    ld a6, 16(sp)
    andi a6, a6, POLY_MASKED
    bnez a6, 85f
'#

# raster.S's plain texel read, as the commit has it
const PLAIN_READ_FIND = r#'    srl a5, s9, s0                  # v at the level
    andi a5, a5, (TILE_SIDE - 1)
    slli a5, a5, TILE_ROW_SHIFT
    srl a6, s8, s0                  # u
    andi a6, a6, (TILE_SIDE - 1)
    slli a6, a6, 2
    add a5, a5, a6
    add a5, a5, a1
    lw a0, 0(a5)
'#

# The plain texel read by the layout, counted under COUNT
const PLAIN_READ_PUT = r#'.if TILE_LAYOUT == LAYOUT_ROWS
    srl a5, s9, s0                  # v at the level
    andi a5, a5, (TILE_SIDE - 1)
    slli a5, a5, TILE_ROW_SHIFT
    srl a6, s8, s0                  # u
    andi a6, a6, (TILE_SIDE - 1)
    slli a6, a6, 2
    add a5, a5, a6
.else
    or a5, s8, s9
    srl a5, a5, s0                  # the texel's bytes in the tile
.endif
    add a5, a5, a1
.ifdef COUNT
    count_tile
.endif
    lw a0, 0(a5)
'#

# raster.S's plain pixel step, as the commit has it
const PLAIN_STEP_FIND = r#'82:
    add s2, s2, s3
    add s8, s8, t5
    add s9, s9, t6
'#

# The plain pixel step across the dilated coordinates' holes
const PLAIN_STEP_PUT = r#'82:
    add s2, s2, s3
.if TILE_LAYOUT == LAYOUT_ROWS
    add s8, s8, t5
    add s9, s9, t6
.else
    or s8, s8, a2
    add s8, s8, t5
    and s8, s8, a3                  # U a pixel on
    or s9, s9, a4
    add s9, s9, t6
    and s9, s9, t3                  # V
.endif
'#

# raster.S's masked texel read, as the commit has it
const MASKED_READ_FIND = r#'    srl a5, s9, s0
    andi a5, a5, (TILE_SIDE - 1)
    slli a5, a5, TILE_ROW_SHIFT
    srl a6, s8, s0
    andi a6, a6, (TILE_SIDE - 1)
    slli a6, a6, 2
    add a5, a5, a6
    add a5, a5, a1
    lw a0, 0(a5)
    srli a5, a0, 31
'#

# The masked texel read by the layout, counted under COUNT
const MASKED_READ_PUT = r#'.if TILE_LAYOUT == LAYOUT_ROWS
    srl a5, s9, s0
    andi a5, a5, (TILE_SIDE - 1)
    slli a5, a5, TILE_ROW_SHIFT
    srl a6, s8, s0
    andi a6, a6, (TILE_SIDE - 1)
    slli a6, a6, 2
    add a5, a5, a6
.else
    or a5, s8, s9
    srl a5, a5, s0
.endif
    add a5, a5, a1
.ifdef COUNT
    count_tile
.endif
    lw a0, 0(a5)
    srli a5, a0, 31
'#

# raster.S's masked pixel step, as the commit has it
const MASKED_STEP_FIND = r#'86:
    add s2, s2, s3
    add s8, s8, t5
    add s9, s9, t6
'#

# The masked pixel step across the dilated coordinates' holes
const MASKED_STEP_PUT = r#'86:
    add s2, s2, s3
.if TILE_LAYOUT == LAYOUT_ROWS
    add s8, s8, t5
    add s9, s9, t6
.else
    or s8, s8, a2
    add s8, s8, t5
    and s8, s8, a3
    or s9, s9, a4
    add s9, s9, t6
    and s9, s9, t3
.endif
'#

# tile.S's row start in a tile build, as the commit has it
const BUILD_ROW_FIND = r#'    slli t2, t0, TILE_ROW_SHIFT
    ld t3, 96(sp)
    add s2, t3, t2                  # the tile's row
'#

# A tile build's row start by the layout's places
const BUILD_ROW_PUT = r#'.if TILE_LAYOUT == LAYOUT_ROWS
    slli t2, t0, TILE_ROW_SHIFT
.else
    la t3, tile_spread
    sh1add t2, t0, t3
    lhu t2, (TILE_SIDE * 2)(t2)
    slli t2, t2, 2                  # the row's part of its texels' places
.endif
    ld t3, 96(sp)
    add s2, t3, t2                  # the tile's row
'#

# tile.S's lanes' branch to the store, as the commit has it
const BUILD_LANES_FIND = r#'    li a6, (3 * CHANNEL_BITS)
    bltu a1, a6, 22b
    j 50f
'#

# The lanes' branch to the layout's placement
const BUILD_LANES_PUT = r#'    li a6, (3 * CHANNEL_BITS)
    bltu a1, a6, 22b
    j .Ltile_place
'#

# tile.S's clamp branch to the store, as the commit has it
const BUILD_CLAMP_FIND = r#'    sub a0, s6, s5                  # the row's rest
    j 50f
'#

# The clamp's branch to the layout's placement
const BUILD_CLAMP_PUT = r#'    sub a0, s6, s5                  # the row's rest
    j .Ltile_place
'#

# tile.S's store loop entry, as the commit has it
const BUILD_ENTRY_FIND = r#'    li s8, 0
    li a0, 1
50:
'#

# The store loop's entry with the layout's u table loaded
const BUILD_ENTRY_PUT = r#'    li s8, 0
    li a0, 1
.Ltile_place:
.if TILE_LAYOUT != LAYOUT_ROWS
    la t5, tile_spread              # a texel's place in its row, the u table
.endif
50:
'#

# tile.S's texel store, as the commit has it
const BUILD_STORE_FIND = r#'    sw a3, 0(s2)
    add s7, s7, s8
    addi s5, s5, 1
    addi s2, s2, 4
'#

# A texel stored at its place in the layout
const BUILD_STORE_PUT = r#'.if TILE_LAYOUT == LAYOUT_ROWS
    sw a3, 0(s2)
.else
    andi t6, s5, (TILE_SIDE - 1)
    sh1add t6, t6, t5
    lhu t6, 0(t6)
    sh2add t6, t6, s2
    sw a3, 0(t6)                    # at its place in the layout
.endif
    add s7, s7, s8
    addi s5, s5, 1
.if TILE_LAYOUT == LAYOUT_ROWS
    addi s2, s2, 4
.endif
'#

# tile.S's read-only section's start, as the commit has it
const TABLES_FIND = r#'.section .rodata
.ifdef DEBUG
msg_alpha:
'#

# The spread tables a layout places its texels by
const TABLES_PUT = r#'.section .rodata
.if TILE_LAYOUT != LAYOUT_ROWS
# A texel's place in its tile from its coordinates at the level: the u
# table, then the v table, a coordinate's six bits spread over its axis's
# places in the index, TILE_PLACE_U's and TILE_PLACE_V's bits in order.
.macro tile_spread_bit i, place, b
.if ((\place) >> (\b)) & 1
.set tile_spread_value, tile_spread_value | ((((\i) >> tile_spread_taken) & 1) << (\b))
.set tile_spread_taken, tile_spread_taken + 1
.endif
.endm
.macro tile_spread_entry i, place
.set tile_spread_value, 0
.set tile_spread_taken, 0
    tile_spread_bit \i, \place, 0
    tile_spread_bit \i, \place, 1
    tile_spread_bit \i, \place, 2
    tile_spread_bit \i, \place, 3
    tile_spread_bit \i, \place, 4
    tile_spread_bit \i, \place, 5
    tile_spread_bit \i, \place, 6
    tile_spread_bit \i, \place, 7
    tile_spread_bit \i, \place, 8
    tile_spread_bit \i, \place, 9
    tile_spread_bit \i, \place, 10
    tile_spread_bit \i, \place, 11
    .hword tile_spread_value
.endm
.balign 2
tile_spread:
.set tile_spread_i, 0
.rept TILE_SIDE
    tile_spread_entry tile_spread_i, TILE_PLACE_U
.set tile_spread_i, tile_spread_i + 1
.endr
.set tile_spread_i, 0
.rept TILE_SIDE
    tile_spread_entry tile_spread_i, TILE_PLACE_V
.set tile_spread_i, tile_spread_i + 1
.endr
.endif
.ifdef DEBUG
msg_alpha:
'#

# main.S's count line's end, as the commit has it
const REPORT_FIND = r#'    la a1, word_count_reentry_end
    call append_str
    call line_end
'#

# The count line with the tiled reads and lines by class
const REPORT_PUT = r#'    la a1, word_count_reentry_end
    call append_str
    la a1, word_count_tiled
    call append_str
    la t0, count_stats
    ld a1, COUNT_TILE_READS_PLANES(t0)
    call append_dec
    la a1, word_count_tiled_in
    call append_str
    la t0, count_stats
    ld a1, COUNT_TILE_LINES_PLANES(t0)
    call append_dec
    la a1, word_count_tiled_planes
    call append_str
    la t0, count_stats
    ld a1, COUNT_TILE_READS_WALLS(t0)
    call append_dec
    la a1, word_count_tiled_in
    call append_str
    la t0, count_stats
    ld a1, COUNT_TILE_LINES_WALLS(t0)
    call append_dec
    la a1, word_count_tiled_walls
    call append_str
    call line_end
'#

# main.S's count line's last words, as the commit has it
const REPORT_WORDS_FIND = r#'word_count_reentry_end:
    .asciz " cut short"
'#

# The count line's words for the tiled reads and lines
const REPORT_WORDS_PUT = r#'word_count_reentry_end:
    .asciz " cut short"
word_count_tiled:
    .asciz "; tiled reads "
word_count_tiled_in:
    .asciz " in "
word_count_tiled_planes:
    .asciz " lines on the planes, "
word_count_tiled_walls:
    .asciz " on the walls"
'#

# world.S's counters zeroed, as the commit has it
const ZERO_FIND = r#'    sd zero, COUNT_REENTRY_CUT(t1)
.endif
'#

# The counters zeroed with the tiled reads and lines
const ZERO_PUT = r#'    sd zero, COUNT_REENTRY_CUT(t1)
    sd zero, COUNT_TILE_READS_PLANES(t1)
    sd zero, COUNT_TILE_READS_WALLS(t1)
    sd zero, COUNT_TILE_LINES_PLANES(t1)
    sd zero, COUNT_TILE_LINES_WALLS(t1)
.endif
'#

# A case's edits, in the order applied
export def main [layout: string, classes: string]: nothing -> list<record<file: string, find: string, put: string>> {
    [
        { file: "render.inc", find: $SETTINGS_FIND, put: ($SETTINGS_PUT | str replace "@CLASSES@" $classes | str replace "@LAYOUT@" $layout) }
        { file: "render.inc", find: $COUNT_FIELDS_FIND, put: $COUNT_FIELDS_PUT }
        { file: "raster.S", find: $COUNT_MACRO_FIND, put: $COUNT_MACRO_PUT }
        { file: "raster.S", find: $SETUP_FIND, put: $SETUP_PUT }
        { file: "raster.S", find: $PLAIN_READ_FIND, put: $PLAIN_READ_PUT }
        { file: "raster.S", find: $PLAIN_STEP_FIND, put: $PLAIN_STEP_PUT }
        { file: "raster.S", find: $MASKED_READ_FIND, put: $MASKED_READ_PUT }
        { file: "raster.S", find: $MASKED_STEP_FIND, put: $MASKED_STEP_PUT }
        { file: "tile.S", find: $BUILD_ROW_FIND, put: $BUILD_ROW_PUT }
        { file: "tile.S", find: $BUILD_LANES_FIND, put: $BUILD_LANES_PUT }
        { file: "tile.S", find: $BUILD_CLAMP_FIND, put: $BUILD_CLAMP_PUT }
        { file: "tile.S", find: $BUILD_ENTRY_FIND, put: $BUILD_ENTRY_PUT }
        { file: "tile.S", find: $BUILD_STORE_FIND, put: $BUILD_STORE_PUT }
        { file: "tile.S", find: $TABLES_FIND, put: $TABLES_PUT }
        { file: "main.S", find: $REPORT_FIND, put: $REPORT_PUT }
        { file: "main.S", find: $REPORT_WORDS_FIND, put: $REPORT_WORDS_PUT }
        { file: "world.S", find: $ZERO_FIND, put: $ZERO_PUT }
    ]
}
