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
use (path self ../knobs) [LEGS LIFTED ONCE QUOTA_KEPT SPAWN STAMP_AT TILE_ROW_TEXELS TILE_TEXELS]

# When HeldPartial places the spawn, in ms
const HELD_AT = 1500

# HeldPartial's O after the placement, in ms
const HELD_ONCE_AFTER = 300

# When HeldPartial's screen is taken, in ms
const HELD_SCREEN_AT = 3000

# When HeldPartial's dump is sent, in ms
const HELD_DUMP_AT = 3200

# When HeldPartial's E is sent, in ms
const HELD_END_AT = 3400

# HeldPartial's bound in seconds
const HELD_SECONDS = 8

# HeldPartial's quota's whole tiles
const HELD_TILES = 32

# HeldPartial's quota's rows past its whole tiles
const HELD_ROWS = 8

# HeldPartial: the spawn's construction held partial through its picture
export def held-partial [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let label = "the held partial"
    let modes = ($LIFTED + $ONCE)
    let quota = ($HELD_TILES * $TILE_TEXELS + $HELD_ROWS * $TILE_ROW_TEXELS)
    let ended = { at: ($HELD_END_AT * 1ms), bytes: (pose command-frame "E") }
    let sends = [
        { at: ($STAMP_AT * 1ms), bytes: (console raise 0 --stamp) }
        { at: ($HELD_AT * 1ms), bytes: (pose pose-frame $SPAWN) }
        { at: (($HELD_AT + $HELD_ONCE_AFTER) * 1ms), bytes: (knobs pool-frame --modes $modes --cold --quota $quota) }
        { at: ($HELD_DUMP_AT * 1ms), bytes: (knobs dump-frame --building) }
        $ended
    ]
    let dir = ($out | path join "held")
    let run = (launch --kernel $kernel --image $image --out $dir --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --screen ($HELD_SCREEN_AT * 1ms) --seconds $HELD_SECONDS)
    assert equal (open --raw $run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)"
    let m = (gauge measure $run.api $LEGS)
    assert ($m.complete and $m.valid and $m.schema == $CLOCK_SCHEMA) $"($label) complete and valid at schema ($CLOCK_SCHEMA): ($m.problems | str join '; ') ($m.invalid | str join '; ')"
    let from = ($m.rows | where {|r| $r.quota == $quota and $r.config_flags == ($modes + $QUOTA_KEPT) } | get -o 0.frame)
    assert ($from != null) $"($label): the O's lift, ONCE, and kept quota of ($quota) texels in force"
    let after = ($m.rows | where {|r| $r.frame >= $from })
    let first_miss = ($after | where {|r| $r.missed_blocks > 0 } | get -o 0.frame)
    assert ($first_miss != null) $"($label): the cold start's view drew blocks without their tiles from frame ($from)"
    let published = ($after | where {|r| $r.tiles_built > 0 } | select frame tiles_built)
    assert ($published == [{ frame: ($first_miss + 1), tiles_built: $HELD_TILES }]) $"($label): one publishing frame after the O, the one after its first miss, ($first_miss + 1), ($HELD_TILES) whole tiles: ($published | first 3)"
    let unheld = ($m.rows | where {|r| $r.frame > $first_miss and $r.building != 1 })
    assert ($unheld | is-empty) $"($label): BUILDING 1 on every frame from ($first_miss + 1) through the end marker's, ($m.final): ($unheld | first 3 | select frame building tiles_built)"
    let read = (evidence dump-keys ($dir | path join "api.out") ($dir | path join "keys.nuon"))
    assert ($read.problems | is-empty) $"($label)'s dump read whole: ($read.problems | first 3)"
    assert equal ($read.dumps | length) 1 $"($label) dumped once"
    let building = ($read.dumps | get 0 | where state == $DUMP_BUILDING | select slot key row)
    assert ((($building | length) == 1) and (($building | get 0.row) == $HELD_ROWS)) $"($label)'s dump holds one BUILDING tile, at row ($HELD_ROWS): ($building)"
    let e_index = ($sends | enumerate | where {|x| $x.item.at == $ended.at and $x.item.bytes == $ended.bytes } | get 0.index)
    let e = { label: $label, measure: $m, capture: (evidence capture-of $run.screen), from: $from, completed: $run.screen_completed, ended: ($run.send_seconds | get $e_index) }
    assert ($e.capture != null) $"($label)'s screen taken"
    let stamp = (picture stamp $e.capture)
    let window = (evidence picture-window $m $from)
    assert equal $window.last_build ($first_miss + 1) $"($label)'s window from the construction's frame"
    let displayed = (if $stamp == null { null } else { evidence displayed-frame $m $window $stamp })
    assert ($displayed != null) $"($label)'s stamp ($stamp) names a frame after the construction's, ($first_miss + 1), and before the end marker's, ($m.final)"
    assert ($e.completed != null and $e.ended != null) $"($label)'s screen completion and E's write recorded: ($e.completed) and ($e.ended)"
    assert ($e.ended > $e.completed) $"($label)'s E written after its screen completed: at ($e.ended) s, the screen at ($e.completed) s"
    let refused = (evidence picture-refusals $e)
    let expected = (($first_miss + 2)..$displayed | each {|f| $f })
    assert ((($refused | length) == 1) and (($refused | get 0.kind) == "unsettled") and (($refused | get 0.frames) == $expected) and ($refused | get 0.detail | str contains "building 1")) $"($label)'s picture refused once, unsettled at every frame from ($first_miss + 2) through the displayed one, ($displayed), BUILDING 1 among the fields: ($refused | each {|r| $'($r.kind): ($r.detail)' } | str join '; ')"
    { from: $from, first_miss: $first_miss, displayed: $displayed, final: $m.final, completed: $e.completed, ended: $e.ended, building: ($building | get 0), refused: ($refused | get 0 | reject frames) }
}
