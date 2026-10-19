use std/assert
use (path self ../../../../../../../jab/nu/mod/launch)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/pose)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/console)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/picture)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/gauge/stream) [CLOCK_SCHEMA]
use (path self ../evidence)
use (path self ../knobs)
use (path self ../knobs) [BAY CAP LEGS LIFTED QUOTA_KEPT REBUILD_TILES SPAWN STALE STAMP_AT TILE_BYTES TILE_TEXELS]

# A boundary's time budget, TILE_ALLOWANCE_US
const ALLOWANCE_US = 1000

# A boundary's tile budget, TILE_QUOTA's tiles of texels
const QUOTA_TILES = 96

# The cycle's legs: each its name, its view, and whether it starts cold
const CYCLE_LEGS = [
    { name: "bay_sight", view: "bay", cold: true }
    { name: "spawn_sight", view: "spawn", cold: true }
    { name: "bay_return", view: "bay", cold: false }
    { name: "spawn_return", view: "spawn", cold: false }
    { name: "bay_again", view: "bay", cold: false }
    { name: "spawn_again", view: "spawn", cold: false }
]

# When the cycle's cap and cold start are sent, in ms
const CYCLE_CAP_AT = 1300

# When the cycle's first leg starts, in ms
const CYCLE_FIRST = 2600

# A cycle leg's length, in ms
const CYCLE_LEG = 1300

# A cold leg's cold start after its placement, in ms
const CYCLE_COLD = 300

# A leg's dump after its placement, in ms
const CYCLE_DUMP = 1100

# The screen after the last leg's dump, in ms
const CYCLE_SCREEN = 150

# The E after the last leg's dump, in ms
const CYCLE_END = 300

# When the reference's spawn is placed with a cold start
const SIGHT_AT = 1500ms

# When the reference's screen is taken
const SIGHT_SCREEN_AT = 4000ms

# When the reference's E is sent
const SIGHT_END_AT = 4500ms

# The reference run's bound in seconds
const SIGHT_SECONDS = 9

# One cycle launched under the O frame's modes and quota, read whole
def cycle-launch [kernel: path, image: path, disk: path, out: path, label: string, name: string, modes: int, quota: int]: nothing -> record {
    let at = {|ms: int, bytes: binary| { at: ($ms * 1ms), bytes: $bytes } }
    let views = { spawn: $SPAWN, bay: $BAY }
    let o = {|| knobs pool-frame --modes $modes --cold --slots $CAP --quota $quota }
    let timed = ($CYCLE_LEGS | enumerate | each {|e| $e.item | insert start ($CYCLE_FIRST + $e.index * $CYCLE_LEG) })
    let leg_sends = ($timed | each {|l|
        [(do $at $l.start (pose pose-frame ($views | get $l.view)))]
        | append (if $l.cold { [(do $at ($l.start + $CYCLE_COLD) (do $o))] } else { [] })
        | append [(do $at ($l.start + $CYCLE_DUMP) (knobs dump-frame))]
    } | flatten)
    let dump_at = (($timed | last | get start) + $CYCLE_DUMP)
    let end_at = ($dump_at + $CYCLE_END)
    let ended = (do $at $end_at (pose command-frame "E"))
    let sends = ([(do $at $STAMP_AT (console raise 0 --stamp)) (do $at $CYCLE_CAP_AT (do $o))] ++ $leg_sends ++ [$ended] | sort-by at)
    let dir = ($out | path join $name)
    let run = (launch --kernel $kernel --image $image --out $dir --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --screen (($dump_at + $CYCLE_SCREEN) * 1ms) --seconds ((($end_at + 4000) / 1000) | math ceil))
    assert equal (open --raw $run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)"
    assert ($run.screen != "") $"($label)'s screen was taken at its last spawn"
    let m = (gauge measure $run.api $LEGS)
    assert ($m.complete and $m.valid and $m.schema == $CLOCK_SCHEMA) $"($label) complete and valid at schema ($CLOCK_SCHEMA): ($m.problems | str join '; ') ($m.invalid | str join '; ')"
    let read = (evidence dump-keys ($dir | path join "api.out") ($dir | path join "keys.nuon"))
    assert ($read.problems | is-empty) $"($label)'s dumps read whole: ($read.problems | first 3)"
    assert equal ($read.dumps | length) ($CYCLE_LEGS | length) $"($label) dumped at every leg's settle: ($read.dumps | length) of ($CYCLE_LEGS | length)"
    let dumps = ($read.dumps | enumerate | each {|e| let l = ($CYCLE_LEGS | get $e.index); { leg: $l.name, view: $l.view, frame: ($e.item | get -o 0.frame), tiles: $e.item } })
    let sets = { bay: ($dumps | get 0 | get tiles | get key), spawn: ($dumps | get 1 | get tiles | get key) }
    let e_index = ($sends | enumerate | where {|x| $x.item.at == $ended.at and $x.item.bytes == $ended.bytes } | get 0.index)
    { run: $run, measure: $m, rows: $m.rows, dumps: $dumps, sets: $sets, ended: ($run.send_seconds | get $e_index) }
}

# The spawn view's settled first sight, the cycle picture's reference
def sight-launch [kernel: path, image: path, disk: path, out: path, label: string]: nothing -> record {
    let ended = { at: $SIGHT_END_AT, bytes: (pose command-frame "E") }
    let sends = [
        { at: ($STAMP_AT * 1ms), bytes: (console raise 0 --stamp) }
        { at: $SIGHT_AT, bytes: (pose pose-frame $SPAWN) }
        { at: $SIGHT_AT, bytes: (knobs pool-frame --cold) }
        $ended
    ]
    let run = (launch --kernel $kernel --image $image --out $out --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --screen $SIGHT_SCREEN_AT --seconds $SIGHT_SECONDS)
    assert equal (open --raw $run.qemu_log) "" $"QEMU has no complaint about the guest on ($label)"
    let m = (gauge measure $run.api $LEGS)
    let e_index = ($sends | enumerate | where {|x| $x.item.at == $ended.at and $x.item.bytes == $ended.bytes } | get 0.index)
    { label: $label, measure: $m, capture: (evidence capture-of $run.screen), from: 0, completed: $run.screen_completed, ended: ($run.send_seconds | get $e_index) }
}

# The two views' keys bracket the cap: each within, their union past
def assert-bracket [c: record, label: string]: nothing -> int {
    let union = ($c.sets.bay | append $c.sets.spawn | uniq | length)
    assert ((($c.sets.bay | length) <= $CAP) and (($c.sets.spawn | length) <= $CAP) and $union > $CAP) $"($label): the bay's ($c.sets.bay | length) keys and the spawn's ($c.sets.spawn | length) each within the cap of ($CAP) and their union, ($union), past it"
    $union
}

# Real eviction and no reset over the cycle's window
def assert-held [c: record, label: string]: nothing -> int {
    let from = ($c.dumps | get 1 | get frame)
    let resets = ($c.rows | where {|r| $r.frame >= $from } | get tile_resets | uniq)
    assert equal ($resets | length) 1 $"($label): no reset in the window from frame ($from), tile_resets ($resets)"
    for d in ($c.dumps | skip 2) {
        let held = ($d.tiles | get key)
        let lost = ($c.sets | get $d.view | where {|k| $k not-in $held })
        assert ($lost | is-empty) $"($label): the ($d.leg) settle's dump holds every key of the ($d.view), ($lost | length) missing: ($lost | first 5)"
    }
    $resets | first
}

# Each phase after the first sights: renewed keys, slots, rows, builds
def cycle-phases [c: record]: nothing -> list<record> {
    2..<($c.dumps | length) | each {|i|
        let d = ($c.dumps | get $i)
        let prev = ($c.dumps | get ($i - 1))
        let prev_keys = ($prev.tiles | get key)
        let renewed = ($c.sets | get $d.view | where {|k| $k not-in $prev_keys } | length)
        let span = ($c.rows | where {|r| $r.frame > $prev.frame and $r.frame <= $d.frame })
        let published = ($span | where {|r| $r.tiles_built > 0 } | get frame)
        {
            leg: $d.leg, view: $d.view, start: ($prev.frame + 1), dump: $d.frame,
            renewed: $renewed, free: ($CAP - ($prev.tiles | length)), span: $span,
            built: ($span | get tiles_built | math sum), evicted: ($span | get evicted | math sum),
            first_miss: ($span | where {|r| $r.missed_blocks > 0 } | get -o 0.frame),
            published: $published, last_build: (if ($published | is-empty) { null } else { $published | last }),
        }
    }
}

# A phase's settled range read as refusals, none when it settles
def settled-refusals [p: record]: nothing -> list<record<kind: string, frame: int, detail: string>> {
    if $p.dump <= $p.last_build {
        return [{ kind: "dump not after", frame: $p.dump, detail: $"the dump at frame ($p.dump) not after the last build at ($p.last_build)" }]
    }
    ($p.last_build + 1)..$p.dump | each {|f|
        let r = ($p.span | where frame == $f | get -o 0)
        if $r == null {
            { kind: "absent", frame: $f, detail: $"frame ($f) absent from the phase's rows" }
        } else if not (evidence settled $r) {
            { kind: "unsettled", frame: $f, detail: (evidence unsettled-fields $r) }
        }
    }
}

# Each phase builds its renewed keys and evicts those past its free slots
def assert-accounting [phases: list<record>, label: string]: nothing -> nothing {
    for p in $phases {
        assert ($p.built == $p.renewed and $p.evicted == ([($p.renewed - $p.free) 0] | math max)) $"($label): the ($p.leg) phase built its ($p.renewed) renewed keys and evicted those past its ($p.free) free slots, built ($p.built), evicted ($p.evicted)"
        assert ($p.first_miss != null) $"($label): the ($p.leg) phase drew blocks without their tiles: ($p.span | first 3 | select frame missed_blocks)"
        let merging = ($p.span | where {|r| $r.frame == ($p.first_miss + 1) } | get -o 0)
        assert ($merging != null and $merging.merged == $p.renewed) $"($label): the ($p.leg) phase's boundary after its first miss, frame ($p.first_miss + 1), merged its ($p.renewed) renewed keys: ($merging | select -o frame merged unprocessed batch_admitted)"
        assert ($p.last_build != null) $"($label): the ($p.leg) phase published"
        let refused = (settled-refusals $p)
        assert ($refused | is-empty) $"($label): the ($p.leg) phase's dump after its last build and every frame between settled, from ($p.last_build + 1) through ($p.dump): ($refused | first 3 | get detail | str join '; ')"
    }
}

# Slots and generations tracked dump to dump, each key's texels alike
def assert-tracking [c: record, label: string]: nothing -> nothing {
    for i in 2..<($c.dumps | length) {
        let d = ($c.dumps | get $i)
        let prev = ($c.dumps | get ($i - 1))
        let pairs = ($prev.tiles | each {|t| let n = ($d.tiles | where slot == $t.slot | get -o 0); if $n == null { null } else { { slot: $t.slot, before: $t, after: $n } } } | compact)
        let kept_wrong = ($pairs | where {|p| $p.before.key == $p.after.key and $p.before.generation != $p.after.generation })
        assert ($kept_wrong | is-empty) $"($label): a slot keeping its key kept its generation into the ($d.leg) dump: ($kept_wrong | first 3 | each {|p| { slot: $p.slot, before: $p.before.generation, after: $p.after.generation } })"
        let stepped_wrong = ($pairs | where {|p| $p.before.key != $p.after.key and $p.after.generation != ($p.before.generation + 1) })
        assert ($stepped_wrong | is-empty) $"($label): a slot taking another key stepped its generation by one into the ($d.leg) dump: ($stepped_wrong | first 3 | each {|p| { slot: $p.slot, before: $p.before.generation, after: $p.after.generation } })"
        let own = ($c.sets | get $d.view)
        let moved = ($prev.tiles | where {|t| $t.key in $own } | where {|t| let n = ($d.tiles | where key == $t.key | get -o 0); $n == null or $n.slot != $t.slot or $n.generation != $t.generation })
        assert ($moved | is-empty) $"($label): every ($d.view) key the dump before held kept its slot and generation into the ($d.leg) dump, ($moved | length) moved: ($moved | first 3 | select key slot generation)"
    }
    let differing = ($c.dumps | each {|d| $d.tiles | select key texels_sha256 } | flatten | uniq | group-by key | items {|k, v| { key: $k, hashes: ($v | length) } } | where hashes > 1)
    assert ($differing | is-empty) $"($label): each key's texels the same in every dump that holds it, ($differing | length) keys differ: ($differing | first 3)"
}

# EvictionCycle: the cycle under the ordinary budget, asserted whole
export def eviction-cycle [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let label = "the eviction cycle"
    let c = (cycle-launch $kernel $image $disk $out $label "cycle" 0 0)
    let union = (assert-bracket $c $label)
    let resets = (assert-held $c $label)
    let phases = (cycle-phases $c)
    assert-accounting $phases $label
    for p in $phases {
        let interval = ($p.span | where {|r| $r.frame > $p.first_miss and $r.frame < $p.last_build })
        let unspent = ($interval | where {|r| $r.tiles_us < $ALLOWANCE_US and $r.tiles_built < $QUOTA_TILES })
        assert ((($interval | length) == ([($p.last_build - $p.first_miss - 1) 0] | math max)) and ($unspent | is-empty)) $"($label): every boundary of the ($p.leg) phase from the one after its first miss, ($p.first_miss + 1), before its last build's, ($p.last_build), spent its budget, ($ALLOWANCE_US) us or ($QUOTA_TILES) tiles: ($unspent | select frame tiles_built tiles_us building | first 3)"
    }
    assert-tracking $c $label

    let rows = $c.rows
    let over = ($rows | where {|r| $r.slots_used > $CAP })
    assert ($over | is-empty) $"($label): slots in use at most ($CAP) on every frame: ($over | first 3 | select frame slots_used)"
    let fixed = ($rows | each {|r| $r.memory - $r.tile_bytes } | uniq)
    assert equal ($fixed | length) 1 $"($label): the memory less the tiles' bytes constant, tile_fixed: ($fixed)"
    let bound = (($fixed | first) + $CAP * $TILE_BYTES)
    let past = ($rows | where {|r| $r.memory > $bound or $r.memory_peak > $bound })
    assert ($past | is-empty) $"($label): the memory and its high-water at most tile_fixed plus ($CAP) tiles, ($bound), from the load on: ($past | first 3 | select frame memory memory_peak)"
    let full = ($rows | where {|r| $r.slots_used == $CAP } | get -o 0.frame)
    assert ($full != null) $"($label): the pool filled to the cap"
    let peaks = ($rows | where {|r| $r.frame >= $full } | get memory_peak | uniq)
    assert equal ($peaks | length) 1 $"($label): the high-water constant from the first full pool, frame ($full): ($peaks)"

    let spawn = ($phases | last)
    assert equal $spawn.view "spawn" $"($label): the final phase the spawn's"
    let pictures = [
        { label: $label, measure: $c.measure, capture: (evidence capture-of $c.run.screen), from: $spawn.start, completed: $c.run.screen_completed, ended: $c.ended }
        (sight-launch $kernel $image $disk ($out | path join "cycle_sight") $"($label)'s reference, the spawn's settled first sight")
    ]
    for e in $pictures {
        let refused = (evidence picture-refusals $e)
        assert ($refused | is-empty) $"($e.label)'s picture bound to a validated, settled frame: ($refused | each {|r| $'($r.kind): ($r.detail)' } | str join '; ')"
    }
    let a = (evidence stamp-written ($pictures | get 0 | get capture) 0)
    let b = (evidence stamp-written ($pictures | get 1 | get capture) 0)
    if $a != $b {
        let rows_apart = (picture rows-differ $a $b [0 0 1920 1080])
        assert false $"($label): the last spawn's screen identical to its settled first sight outside the stamp's cells, ($rows_apart | length) rows differing from row ($rows_apart | get -o 0)"
    }
    let framed = ($pictures | each {|e|
        let window = (evidence picture-window $e.measure $e.from)
        let stamp = (picture stamp $e.capture)
        { label: $e.label, last_build: $window.last_build, displayed: (evidence displayed-frame $e.measure $window $stamp), final: $window.final, completed: $e.completed, ended: $e.ended }
    })

    {
        bay_keys: ($c.sets.bay | length), spawn_keys: ($c.sets.spawn | length), union: $union, cap: $CAP, resets: $resets,
        phases: ($phases | each {|p| { leg: $p.leg, renewed: $p.renewed, free: $p.free, built: $p.built, evicted: $p.evicted, first_miss: $p.first_miss, last_build: $p.last_build, settled: ($p.last_build + 1), frames: ($p.last_build + 1 - $p.first_miss), boundaries: ($p.span | where {|r| $r.frame > $p.first_miss and $r.frame <= $p.last_build } | each {|r| $"($r.frame):($r.tiles_built)/($r.evicted)/($r.tiles_us)" } | str join " ") } }),
        fixed: ($fixed | first), memory_max: ($rows | get memory | math max), peak: ($peaks | first), full_at: $full,
        dumps: ($c.dumps | each {|d| { leg: $d.leg, frame: $d.frame, tiles: ($d.tiles | length) } }),
        pictures: $framed,
    }
}

# RebuildBound: the cycle under the lift and a quota of whole tiles
export def rebuild-bound [kernel: path, image: path, disk: path, out: path]: nothing -> record {
    let label = "the rebuild bound"
    let modes = ($LIFTED + $STALE)
    let quota = ($REBUILD_TILES * $TILE_TEXELS)
    let c = (cycle-launch $kernel $image $disk $out $label "rebuild" $modes $quota)
    let from = ($c.rows | where {|r| $r.quota == $quota } | get -o 0.frame)
    assert ($from != null) $"($label): the quota of ($quota) texels in force"
    let configured = ($c.rows | where {|r| $r.frame >= $from })
    let unkept = ($configured | where {|r| $r.quota != $quota or $r.config_flags != ($modes + $QUOTA_KEPT) or $r.slots_effective != $CAP })
    assert ($unkept | is-empty) $"($label): every frame from ($from) under the lift, the stale mode, and the kept quota of ($quota) on ($CAP) slots: ($unkept | first 3 | select frame quota config_flags slots_effective)"
    let union = (assert-bracket $c $label)
    let resets = (assert-held $c $label)
    let phases = (cycle-phases $c)
    assert-accounting $phases $label
    for p in $phases {
        let n = (($p.renewed + $REBUILD_TILES - 1) // $REBUILD_TILES)
        let frames = (0..<$n | each {|i| $p.first_miss + 1 + $i })
        let expected = ($frames | enumerate | each {|e| { frame: $e.item, tiles_built: (if $e.index < ($n - 1) { $REBUILD_TILES } else { $p.renewed - $REBUILD_TILES * ($n - 1) }), building: 0 } })
        let read = ($frames | each {|f| $p.span | where frame == $f | get -o 0 | default { frame: $f, tiles_built: null, building: null } | select frame tiles_built building })
        let wrong = ($read | zip $expected | where {|w| $w.0 != $w.1 } | each {|w| $w.0 })
        assert ($wrong | is-empty) $"($label): the ($p.leg) phase's ($p.renewed) keys published at frames ($p.first_miss + 1) through ($p.first_miss + $n), ($REBUILD_TILES) whole tiles at each before the last and BUILDING 0 at every one: ($wrong | first 3)"
        let elsewhere = ($p.published | where {|f| $f not-in $frames })
        assert ($elsewhere | is-empty) $"($label): no other frame of the ($p.leg) phase published: ($elsewhere | first 3)"
    }
    assert-tracking $c $label
    {
        bay_keys: ($c.sets.bay | length), spawn_keys: ($c.sets.spawn | length), union: $union, cap: $CAP, resets: $resets, quota: $quota,
        phases: ($phases | each {|p| { leg: $p.leg, renewed: $p.renewed, free: $p.free, built: $p.built, evicted: $p.evicted, first_miss: $p.first_miss, last_build: $p.last_build, boundaries: ($p.published | length), counts: ($p.span | where {|r| $r.tiles_built > 0 } | get tiles_built | str join " ") } }),
    }
}
