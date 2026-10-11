# TileLayout's LayoutProbe candidates: jab's game/fps `src` at a commit
# copied to <cands>/layout_<case>_<commit> beside a candidate's manifest,
# the checkout's SDK by absolute path, the layout's edits applied to
# render.inc, raster.S, tile.S, main.S, and world.S, each find matched
# exactly once. A case is a layout and a class setting: rows, blocks
# (four-by-four squares of texels in row order), or Morton (the index's
# twelve bits interleaved), under the walls alone or the walls with the
# planes; the count cases are the planes' for `--set debug,count`, a
# COUNT build landing in a tree of its own. The layouts other than rows
# address a texel by dilated coordinates: u and v each hold their bits
# below the texel beside their texel's bits spread to the axis's places
# in the index, a pixel's step adds across the holes filled, and the
# texel is (U | V) shifted down to its bytes. Rows assembles span_fill's
# and tile_build's code as the commit has it; COUNT's tile counters
# count a tiled block's reads and the 64-byte lines they enter by class.
# `layout.just`'s `layout-cands` runs it.

const GAME = (path self | path dirname | path join .. .. .. .. jab game fps)

const CASES = [
    { name: "rows_walls", layout: "LAYOUT_ROWS", classes: "TILE_CLASS_WALLS" }
    { name: "blocks_walls", layout: "LAYOUT_BLOCKS", classes: "TILE_CLASS_WALLS" }
    { name: "morton_walls", layout: "LAYOUT_MORTON", classes: "TILE_CLASS_WALLS" }
    { name: "rows_planes", layout: "LAYOUT_ROWS", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "blocks_planes", layout: "LAYOUT_BLOCKS", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "morton_planes", layout: "LAYOUT_MORTON", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "rows_count", layout: "LAYOUT_ROWS", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "blocks_count", layout: "LAYOUT_BLOCKS", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "morton_count", layout: "LAYOUT_MORTON", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
]

const SETTINGS_FIND = r#'.set TILE_CLASSES, TILE_CLASS_WALLS
'#

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

const COUNT_FIELDS_FIND = r#'.set COUNT_REENTRY_CUT, 80
.set COUNT_SIZE, 88
'#

const COUNT_FIELDS_PUT = r#'.set COUNT_REENTRY_CUT, 80
.set COUNT_TILE_READS_PLANES, 88
.set COUNT_TILE_READS_WALLS, 96
.set COUNT_TILE_LINES_PLANES, 104
.set COUNT_TILE_LINES_WALLS, 112
.set COUNT_SIZE, 120
'#

const COUNT_MACRO_FIND = r#'.ifdef COUNT
.macro count_add field, scratch, base, n=1
    addi \base, tp, CTX_COUNT
    ld \scratch, \field(\base)
    addi \scratch, \scratch, \n
    sd \scratch, \field(\base)
.endm
.endif
'#

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

const SETUP_FIND = r#'    li t4, 0
    sd s5, 40(sp)
    mv t2, s11
    ld a6, 16(sp)
    andi a6, a6, POLY_MASKED
    bnez a6, 85f
'#

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

const PLAIN_STEP_FIND = r#'82:
    add s2, s2, s3
    add s8, s8, t5
    add s9, s9, t6
'#

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

const MASKED_STEP_FIND = r#'86:
    add s2, s2, s3
    add s8, s8, t5
    add s9, s9, t6
'#

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

const BUILD_ROW_FIND = r#'    slli t2, t0, TILE_ROW_SHIFT
    ld t3, 96(sp)
    add s2, t3, t2                  # the tile's row
'#

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

const BUILD_LANES_FIND = r#'    li a6, (3 * CHANNEL_BITS)
    bltu a1, a6, 22b
    j 50f
'#

const BUILD_LANES_PUT = r#'    li a6, (3 * CHANNEL_BITS)
    bltu a1, a6, 22b
    j .Ltile_place
'#

const BUILD_CLAMP_FIND = r#'    sub a0, s6, s5                  # the row's rest
    j 50f
'#

const BUILD_CLAMP_PUT = r#'    sub a0, s6, s5                  # the row's rest
    j .Ltile_place
'#

const BUILD_ENTRY_FIND = r#'    li s8, 0
    li a0, 1
50:
'#

const BUILD_ENTRY_PUT = r#'    li s8, 0
    li a0, 1
.Ltile_place:
.if TILE_LAYOUT != LAYOUT_ROWS
    la t5, tile_spread              # a texel's place in its row, the u table
.endif
50:
'#

const BUILD_STORE_FIND = r#'    sw a3, 0(s2)
    add s7, s7, s8
    addi s5, s5, 1
    addi s2, s2, 4
'#

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

const TABLES_FIND = r#'.section .rodata
.ifdef DEBUG
msg_alpha:
'#

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

const REPORT_FIND = r#'    la a1, word_count_reentry_end
    call append_str
    call line_end
'#

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

const REPORT_WORDS_FIND = r#'word_count_reentry_end:
    .asciz " cut short"
'#

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

const ZERO_FIND = r#'    sd zero, COUNT_REENTRY_CUT(t1)
.endif
'#

const ZERO_PUT = r#'    sd zero, COUNT_REENTRY_CUT(t1)
    sd zero, COUNT_TILE_READS_PLANES(t1)
    sd zero, COUNT_TILE_READS_WALLS(t1)
    sd zero, COUNT_TILE_LINES_PLANES(t1)
    sd zero, COUNT_TILE_LINES_WALLS(t1)
.endif
'#

# A case's edits, in the order applied.
def edits [layout: string, classes: string]: nothing -> list<record<file: string, find: string, put: string>> {
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

def main [cands: path, commit: string, ...names: string] {
    let jab = ($GAME | path join .. .. | path expand)
    let head = (^git -C $jab rev-parse HEAD | str trim)
    if not ($head | str starts-with $commit) {
        error make { msg: $"the checkout is at ($head), not ($commit)" }
    }
    let changed = (^git -C $jab status --porcelain -- game/fps/src | str trim)
    if $changed != "" { error make { msg: $"the checkout's src has changes: ($changed)" } }
    let unknown = ($names | where {|n| $n not-in ($CASES | get name) })
    if ($unknown | is-not-empty) { error make { msg: $"no such case: ($unknown | str join ', ')" } }
    let sdk = ($jab | path join "sdk")
    let manifest = ([
        "name = 'fps'"
        $"sdk = '($sdk)'"
        $"workspace = '($jab)'"
        $"includes = ['($sdk | path join src)']"
        $"link = '($sdk | path join src program.ld)'"
    ] | str join (char nl)) + (char nl)
    for c in ($CASES | where {|c| ($names | is-empty) or ($c.name in $names) }) {
        let dir = ($cands | path join $"layout_($c.name)_($commit)")
        let src = ($dir | path join "src")
        if ($dir | path exists) {
            # ours only: a candidate tree of this name, its src replaced
            if not (($dir | path join "program.jab.toml" | path exists) and ($src | path type) == "dir") {
                error make { msg: $"($dir) exists and is not a candidate tree; refusing to replace it" }
            }
            rm -r $src
        } else {
            mkdir $dir
        }
        $manifest | save --raw -f ($dir | path join "program.jab.toml")
        cp -r ($GAME | path join "src") $dir
        for e in (edits $c.layout $c.classes) {
            let file = ($src | path join $e.file)
            let text = (open --raw $file | decode utf-8)
            let n = (($text | split row $e.find | length) - 1)
            if $n != 1 {
                error make { msg: $"($c.name): a find in ($e.file) matched ($n) times, where one is applied: ($e.find | lines | first)" }
            }
            $text | str replace $e.find $e.put | save --raw -f $file
        }
        print $"($c.name): ($dir)"
    }
}
