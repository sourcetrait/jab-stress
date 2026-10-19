use std/assert
use (path self ../../../../../../../jab/nu/mod/launch)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/pose)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/console)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/picture)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/gauge/stream) [CLOCK_SCHEMA]
use (path self ../evidence)
use (path self ../knobs)
use (path self ../evidence) [DUMP_BUILDING]
use (path self ../knobs) [CAP FROZEN LIFTED ONCE QUOTA_KEPT REBUILD_TILES SPAWN STALE STAMP_AT TILE_ROW_TEXELS TILE_SIDE TILE_TEXELS YARD]

# When SlotReuse's L lights every lumel full bright, in ms
const REUSE_LEVEL_AT = 1000

# When SlotReuse's W puts two workers in fixed bands, in ms
const REUSE_WORKERS_AT = 1050

# When SlotReuse's J holds worker 2, in ms
const REUSE_HOLD_AT = 1100

# When SlotReuse's cap and cold start are sent, in ms
const REUSE_CAP_AT = 1300

# When SlotReuse dumps the spawn's settle, in ms
const REUSE_SPAWN_DUMP = 2300

# When SlotReuse places the yard, in ms
const REUSE_YARD = 2500

# When SlotReuse dumps the yard's settle, in ms
const REUSE_YARD_DUMP = 3600

# When SlotReuse sends its quota with ONCE, in ms
const REUSE_ONCE = 3800

# When SlotReuse returns to the spawn, in ms
const REUSE_RETURN = 4100

# When SlotReuse dumps with the tile in construction, in ms
const REUSE_DUMP = 4500

# When SlotReuse's screen is taken, in ms
const REUSE_SCREEN = 4700

# When SlotReuse's E is sent, in ms
const REUSE_END = 4900

# SlotReuse's bound in seconds
const REUSE_SECONDS = 9

# SlotReuse's quota's whole tiles
const REUSE_TILES = 50

# SlotReuse's quota's rows past its whole tiles
const REUSE_ROWS = 8

# When SlotReuse's reference places the spawn, in ms
const REUSE_HELD_AT = 1500

# When SlotReuse's reference's screen is taken, in ms
const REUSE_HELD_SCREEN = 2700

# When SlotReuse's reference's E is sent, in ms
const REUSE_HELD_END = 2900

# SlotReuse's reference's bound in seconds
const REUSE_HELD_SECONDS = 7

# The line a boundary before its round joined ends a guest with
const BOUNDARY_UNJOINED = "fps: tile boundary before the round joined"

# The line a held job's watchdog ends a guest with
const HOLD_EXPIRED = "fps: held job never released"

# SlotReuse: a partial tile, stale entries, a held worker, in one launch
export def slot-reuse [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let label = "the slot reuse"
    let at = {|ms: int, bytes: binary| { at: ($ms * 1ms), bytes: $bytes } }
    let knobs = {|held: bool| [
        (do $at $REUSE_LEVEL_AT (knobs level-frame true $held))
        (do $at $REUSE_WORKERS_AT (console workers 2 0))
        (do $at $REUSE_HOLD_AT (knobs jobs-frame 2 0 false 0 --hold))
        (do $at $STAMP_AT (console raise 0 --stamp))
    ] }
    let stale = ($LIFTED + $STALE)
    let once = ($LIFTED + $STALE + $ONCE)
    let quota = ($REUSE_TILES * $TILE_TEXELS + $REUSE_ROWS * $TILE_ROW_TEXELS)
    let ended = (do $at $REUSE_END (pose command-frame "E"))
    let sends = ((do $knobs false) ++ [
        (do $at ($REUSE_CAP_AT - 50) (pose pose-frame $SPAWN))
        (do $at $REUSE_CAP_AT (knobs pool-frame --modes $stale --cold --slots $CAP --quota ($REBUILD_TILES * $TILE_TEXELS)))
        (do $at $REUSE_SPAWN_DUMP (knobs dump-frame))
        (do $at $REUSE_YARD (pose pose-frame $YARD))
        (do $at $REUSE_YARD_DUMP (knobs dump-frame))
        (do $at $REUSE_ONCE (knobs pool-frame --modes $once --slots $CAP --quota $quota))
        (do $at $REUSE_RETURN (pose pose-frame $SPAWN))
        (do $at $REUSE_DUMP (knobs dump-frame --building))
        $ended
    ] | sort-by at)
    let dir = ($out | path join "reuse")
    let run = (launch --kernel $kernel --image $image --out $dir --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --screen ($REUSE_SCREEN * 1ms) --seconds $REUSE_SECONDS)
    let said = ($run.serial | lines)
    assert (not ($said | any {|l| $l | str contains $BOUNDARY_UNJOINED })) $"($label): the boundary ran before its round joined, exit 15: `($BOUNDARY_UNJOINED)`, status ($run.status)"
    assert (not ($said | any {|l| $l | str contains $HOLD_EXPIRED })) $"($label): unexercised, the hold expired unreleased, exit 16: `($HOLD_EXPIRED)`, status ($run.status)"
    assert equal (open --raw $run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)"
    assert ($run.screen != "") $"($label)'s screen taken"
    let ref_ended = (do $at $REUSE_HELD_END (pose command-frame "E"))
    let ref_sends = ((do $knobs true) ++ [(do $at $REUSE_HELD_AT (pose pose-frame $SPAWN)) $ref_ended] | sort-by at)
    let ref_run = (launch --kernel $kernel --image $image --out ($out | path join "reuse_held") --set DEBUG --sound --api --disk $disk --serial "fps" --send $ref_sends --screen ($REUSE_HELD_SCREEN * 1ms) --seconds $REUSE_HELD_SECONDS)
    assert equal (open --raw $ref_run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)'s reference"
    assert ($ref_run.screen != "") $"($label)'s reference's screen taken"

    let legs = [
        { name: "start", places: [], pad: [] }
        { name: "spawn", places: [$SPAWN], pad: [] }
        { name: "yard", places: [$YARD], pad: [] }
        { name: "return", places: [$SPAWN], pad: [] }
    ]
    let m = (gauge measure $run.api $legs)
    assert ($m.complete and $m.valid and $m.schema == $CLOCK_SCHEMA) $"($label) complete and valid at schema ($CLOCK_SCHEMA): ($m.problems | str join '; ') ($m.invalid | str join '; ')"
    let placed = ($m.rows | where leg == "return" | get -o 0.frame)
    assert ($placed != null) $"($label): the final spawn placement recorded"
    let configured = ($m.rows | where {|r| $r.quota == $quota and $r.config_flags == ($once + $QUOTA_KEPT) } | get -o 0.frame)
    assert ($configured != null and $configured <= ($placed - 1)) $"($label): the ONCE's configuration in force from frame ($configured), before the final spawn placement at ($placed)"
    let e_index = ($sends | enumerate | where {|x| $x.item.at == $ended.at and $x.item.bytes == $ended.bytes } | get 0.index)
    let evidence = { label: $label, measure: $m, capture: (evidence capture-of $run.screen), from: ($placed + 1), published: true, completed: $run.screen_completed, ended: ($run.send_seconds | get $e_index) }
    let refused = (evidence picture-refusals $evidence)
    assert (($refused | where kind != "unsettled") | is-empty) $"($label)'s picture bound after its final spawn placement, refused for nothing but unsettled: ($refused | each {|r| $'($r.kind): ($r.detail)' } | str join '; ')"
    let ref_legs = [{ name: "start", places: [], pad: [] }, { name: "spawn", places: [$SPAWN], pad: [] }]
    let ref_m = (gauge measure $ref_run.api $ref_legs)
    assert ($ref_m.complete and $ref_m.valid and $ref_m.schema == $CLOCK_SCHEMA) $"($label)'s reference complete and valid at schema ($CLOCK_SCHEMA): ($ref_m.problems | str join '; ') ($ref_m.invalid | str join '; ')"
    let ref_placed = ($ref_m.rows | where leg == "spawn" | get -o 0)
    assert ($ref_placed != null and (($ref_placed.config_flags bit-and $FROZEN) != 0)) $"($label)'s reference's spawn placement recorded under the frozen configuration: ($ref_placed | select -o frame config_flags)"
    let ref_index = ($ref_sends | enumerate | where {|x| $x.item.at == $ref_ended.at and $x.item.bytes == $ref_ended.bytes } | get 0.index)
    let ref_evidence = { label: $"($label)'s reference", measure: $ref_m, capture: (evidence capture-of $ref_run.screen), from: $ref_placed.frame, published: false, completed: $ref_run.screen_completed, ended: ($ref_run.send_seconds | get $ref_index) }
    let ref_refused = (evidence picture-refusals $ref_evidence)
    assert (($ref_refused | where kind != "unsettled") | is-empty) $"($label)'s reference's picture bound from its spawn placement, refused for nothing but unsettled: ($ref_refused | each {|r| $'($r.kind): ($r.detail)' } | str join '; ')"
    let ref_shown = (evidence displayed-frame $ref_m (evidence picture-window $ref_m $ref_placed.frame) (picture stamp $ref_evidence.capture))
    let tiled = ($ref_m.rows | where {|r| $r.frame >= $ref_placed.frame and $r.frame <= $ref_shown and ($r.tiled_pixels != 0 or $r.tiles_built != 0 or $r.building != 0) })
    assert ($tiled | is-empty) $"($label)'s reference held off its tiles from its placement, frame ($ref_placed.frame), through its displayed one, ($ref_shown): ($tiled | first 3 | select frame tiled_pixels tiles_built building)"

    let a = (evidence stamp-written $evidence.capture 0)
    let b = (evidence stamp-written $ref_evidence.capture 0)
    if $a != $b {
        let rows_apart = (picture rows-differ $a $b [0 0 1920 1080])
        let first_row = ($rows_apart | get -o 0)
        let pixels = (if $first_row == null { [] } else { evidence pixels-differ $a $b $first_row 5 })
        assert false $"($label): the screen the bright spawn view held off its tiles outside the stamp's cells, ($rows_apart | length) rows differing from row ($first_row), its first pixels apart ($pixels)"
    }

    let first_miss = ($m.rows | where {|r| $r.frame >= $placed and $r.missed_blocks > 0 } | get -o 0.frame)
    assert ($first_miss != null) $"($label): the spawn's return drew blocks without their tiles from its placement at ($placed)"
    let published = ($m.rows | where {|r| $r.frame >= $configured and $r.tiles_built > 0 } | select frame tiles_built)
    assert ($published == [{ frame: ($first_miss + 1), tiles_built: $REUSE_TILES }]) $"($label): one construction since the ONCE, at the frame after the spawn's first miss, ($first_miss + 1), publishing ($REUSE_TILES): ($published | first 3)"
    let unheld = ($m.rows | where {|r| $r.frame > $first_miss and $r.building != 1 })
    assert ($unheld | is-empty) $"($label): BUILDING 1 on every frame from ($first_miss + 1) through the end marker's, ($m.final): ($unheld | first 3 | select frame building tiles_built)"
    let displayed = (evidence displayed-frame $m (evidence picture-window $m ($placed + 1)) (picture stamp $evidence.capture))
    let shown = ($m.rows | where frame == $displayed | get 0)
    assert ($shown.building == 1 and $shown.missed_blocks > 0) $"($label): the displayed frame ($displayed)'s records BUILDING 1 and blocks missed: ($shown | select frame building missed_blocks)"

    let read = (evidence dump-keys ($dir | path join "api.out") ($dir | path join "keys.nuon"))
    assert ($read.problems | is-empty) $"($label)'s dumps read whole: ($read.problems | first 3)"
    assert equal ($read.dumps | length) 3 $"($label) dumped the spawn, the yard, and the return"
    let spawn_tiles = ($read.dumps | get 0)
    let yard_tiles = ($read.dumps | get 1)
    let spawn_keys = ($spawn_tiles | get key)
    let spawn_hashes = ($spawn_tiles | get texels_sha256)
    let alike = ($yard_tiles | where {|t| ($t.key not-in $spawn_keys) and ($t.texels_sha256 in $spawn_hashes) })
    assert ($alike | is-empty) $"($label): no tile of the yard's own keys with a spawn tile's texels whole: ($alike | length) alike, ($alike | first 3 | select -o slot key surface)"
    let building = ($read.dumps | get 2 | where state == $DUMP_BUILDING)
    assert equal ($building | length) 1 $"($label)'s last dump holds one BUILDING tile: ($building | select -o slot key row)"
    let partial = ($building | first)
    let complete = ($spawn_tiles | where key == $partial.key | get -o 0)
    assert ($complete != null and $partial.row == $REUSE_ROWS) $"($label): the BUILDING tile a spawn key's at row ($REUSE_ROWS): key ($partial.key), row ($partial.row)"
    let left = ($yard_tiles | where slot == $partial.slot | get -o 0)
    assert ($left != null and ($left.key not-in $spawn_keys)) $"($label): the BUILDING tile's slot ($partial.slot) a yard tile's at the yard's settle: ($left | select -o key generation)"
    let rows = (evidence tile-rows $run.api $partial)
    let whole = (evidence tile-rows $run.api $complete)
    let old = (evidence tile-rows $run.api $left)
    let built_wrong = (0..<$REUSE_ROWS | where {|y| ($rows | get $y) != ($whole | get $y) })
    assert ($built_wrong | is-empty) $"($label): the partial tile's rows below ($REUSE_ROWS) its key's complete rows, rows ($built_wrong) differing"
    let unbuilt_new = ($REUSE_ROWS..<$TILE_SIDE | where {|y| ($rows | get $y) != ($old | get $y) })
    assert ($unbuilt_new | is-empty) $"($label): the partial tile's rows from ($REUSE_ROWS) the evicted yard tile's, rows ($unbuilt_new | first 5) differing"
    let unbuilt_apart = ($REUSE_ROWS..<$TILE_SIDE | where {|y| ($rows | get $y) != ($whole | get $y) })
    assert ($unbuilt_apart | is-not-empty) $"($label): the partial tile's rows from ($REUSE_ROWS) differ from its key's complete rows in at least one texel"
    {
        configured: $configured, placed: $placed, first_miss: $first_miss, displayed: $displayed, final: $m.final, completed: $evidence.completed, ended: $evidence.ended,
        partial: ($partial | select slot key row generation), left: ($left | select key generation), unbuilt_apart: ($unbuilt_apart | length),
        refused: ($refused | each {|r| $r | reject frames }), reference: { placed: $ref_placed.frame, displayed: $ref_shown, final: $ref_m.final },
    }
}
