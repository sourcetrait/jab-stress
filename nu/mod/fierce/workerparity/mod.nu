use (path self ../../../../../jab/nu/mod/launch)
use (path self ../../../../../jab/kit/fierce/nu/mod/pose)
use (path self ../../../../../jab/kit/fierce/nu/mod/console)
use (path self ../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../jab/kit/fierce/nu/mod/picture)
use (path self ../../../../../jab/kit/fierce/nu/mod/tree)

# The game's directory in jab, checked out beside the workbench
const GAME = path self ../../../../../jab/kit/fierce

# The frame line's pattern, its bands a count a hart
const FRAME = "fps: frame in {us} us: {sectors} sectors, {walls} walls, {pieces} pieces, {planes} planes, {openings} openings, {sprites} sprites, {uncovered} uncovered; clear, planes, walls, portals, sprites, raster us {clear}, {plane_us}, {wall_us}, {portal_us}, {sprite_us}, {raster_us}; spans {spans}, pixels {pixels}, lit spans {lit_spans}, lit pixels {lit_pixels}, light us {light_us}, rejected {rejected}, samples {samples}, tiles built {tiles_built}, tiled {tiled}, resets {resets}, slots {slots}, commands {commands}, flushes {flushes}, workers {workers}, grain {grain}, rounds {rounds}, bands {bands1} {bands2} {bands3} {bands4} {bands5} {bands6} {bands7}, dispatch us {dispatch}, barrier us {barrier}, slowest us {slowest}, busy us {busy}, cancelled {cancelled}"

# The drawing's counts judged against W 0's
const COUNTS = [spans pixels lit_spans lit_pixels rejected samples tiled commands flushes uncovered]

# render.inc's GFX_SLOTS, the W frame's greatest count
const GFX_SLOTS = 7

# An API record's bytes
const RECORD = 64

# A state record's kind in an API record
const STATE_KIND = 1

# A console answer's kind in an API record
const CONSOLE_KIND = 11

# The console's J as its answer carries it
const CONSOLE_J = 74

# The console's P as its answer carries it
const CONSOLE_P = 80

# When the stamp goes on, under the picture contract
const STAMP_AT = 200ms

# When the screen is taken, under the picture contract
const SCREEN_AT = 9000ms

# A run's bound in seconds, so its final records land
const SECONDS = 11

# The status of a run its bound ends, jab launch's
const BOUND_STATUS = 124

# The console's W frame: the workers and their grain
export def workers-frame [workers: int, grain: int]: nothing -> binary {
    [("W" | into binary), 0x[00 00 00], ($workers | into binary | bytes at 0..<1), 0x[00 00 00], ($grain | into binary | bytes at 0..<4), (0..<52 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The console's J frame: every round cancelled, or a hart's worker faulted
export def jobs-frame [cancel: bool, fault: int]: nothing -> binary {
    [("J" | into binary), 0x[00 00 00], 0x[00], 0x[00 00 00], 0x[00 00 00 00], (if $cancel { 0x[01] } else { 0x[00] }), ($fault | into binary | bytes at 0..<1), 0x[00], (0..<49 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The frames that read a console command, by the state records before it
export def answered-frames [api: binary, command: int]: nothing -> list<int> {
    mut states = 0
    mut frames = []
    for r in ($api | chunks $RECORD | where {|c| ($c | bytes length) == $RECORD }) {
        let kind = ($r | bytes at 0..<4 | into int --endian little)
        if $kind == $STATE_KIND { $states += 1 }
        if $kind == $CONSOLE_KIND and ($r | bytes at 4..<8 | into int --endian little) == $command { $frames = ($frames | append $states) }
    }
    $frames
}

# The poses a parity may take, each eye at rest on the floor beneath it
def poses-all []: nothing -> list<any> {
    [
        { name: r1_spawn, x: 4.0, y: 4.0, z: 1.6, yaw: 0, pitch: 0 }
        { name: r1_window, x: 5.0, y: 4.0, z: 4.85, yaw: 0, pitch: -20 }
        { name: r1_grate, x: 9.0, y: 11.0, z: 1.6, yaw: 0, pitch: 0 }
        { name: r1_landing, x: 12.0, y: 4.0, z: 3.1, yaw: 90, pitch: 10 }
        { name: r1_ramp, x: 12.0, y: 6.5, z: 3.975, yaw: 90, pitch: -30 }
        { name: r1_door, x: 4.0, y: 5.0, z: 1.6, yaw: 90, pitch: 0 }
        { name: r1_light, x: 4.0, y: 4.0, z: 1.6, yaw: 180, pitch: -45 }
        { name: spawn, x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }
        { name: yard, x: 40.0, y: 6.0, z: 1.6, yaw: 90, pitch: 10 }
        { name: window, x: 8.75, y: 17.0, z: 4.6, yaw: 0, pitch: -15 }
        { name: bay, x: 20.0, y: 17.0, z: 1.6, yaw: 180, pitch: 5 }
        { name: up, x: 8.75, y: 3.5, z: 1.6, yaw: 90, pitch: 15 }
        { name: down, x: 1.5, y: 3.5, z: 1.6, yaw: 90, pitch: -15 }
        { name: garage, x: 16.0, y: 14.0, z: -1.4, yaw: 0, pitch: 0 }
    ]
}

# Modes parsed from workers:grain pairs, each within GFX_SLOTS
def modes-of [modes: string]: nothing -> list<any> {
    let parsed = ($modes | split row "," | each {|m| let p = ($m | split row ":"); { workers: ($p.0 | into int), grain: ($p.1 | into int) } })
    let outside = ($parsed | where {|m| $m.workers < 0 or $m.workers > $GFX_SLOTS })
    if not ($outside | is-empty) { error make { msg: $"a mode's workers run 0 to ($GFX_SLOTS): ($outside | to nuon)" } }
    $parsed
}

# A map's still copy compiled into `out`, its romfs disk and digest
export def disk-of [map: string, out: path]: nothing -> record<name: string, tree: string, disk: string, sha256: string> {
    let src = ($GAME | path join "content" "map" $"($map).nuon")
    if not ($src | path exists) { error make { msg: $"no map source ($src): --map names a map of the game's content, render_0 or render_1" } }
    let name = $"($map)_still"
    let tree = (tree variant (open $src) $name [android] ($out | path join "tree") $GAME)
    let disk = ($out | path join $"($name).romfs")
    let made = (^genromfs -d $tree -f $disk -V "fps" | complete)
    if $made.exit_code != 0 { error make { msg: $"genromfs: ($made.stderr)" } }
    { name: $name, tree: $tree, disk: $disk, sha256: (open --raw $disk | hash sha256) }
}

# A launch's sends under the picture contract
def sends-of [p: record, m: record, cancel: bool, end: duration]: nothing -> list<any> {
    let cancels = (if $cancel { [{ at: 200ms, bytes: (jobs-frame true 0) }] } else { [] })
    [{ at: $STAMP_AT, bytes: (console raise 0 --stamp) }, { at: 200ms, bytes: (workers-frame $m.workers $m.grain) }] ++ $cancels ++ [
        { at: 1900ms, bytes: (pose command-frame "L") }
        { at: 2000ms, bytes: (pose pose-frame $p) }
        { at: 8000ms, bytes: (pose pose-frame $p) }
        { at: $end, bytes: (pose command-frame "E") }
    ] | sort-by at
}

# A run's screen bound to the frame it shows
def bind [run: record, p: record, m: record, cancel: bool]: nothing -> record<stamp: any, from: any, frame: any, problems: list<string>> {
    let placed = (answered-frames $run.api $CONSOLE_P)
    if $run.screen == "" { return { stamp: null, from: ($placed | get -o 1), frame: null, problems: ["no screen was taken"] } }
    let stamp = (picture stamp (open --raw $run.screen | into binary))
    if ($placed | length) < 2 { return { stamp: $stamp, from: null, frame: null, problems: [$"the second placement unanswered: ($placed | length) answered"] } }
    let measured = (gauge measure $run.api [{ name: "start", places: [], pad: [] }, { name: "placed", places: [$p $p], pad: [] }])
    let witness = (if not $cancel { null } else if $m.workers == 0 { "serial" } else { "worker" })
    let expect = { pose: ($p | select x y z yaw pitch | insert roll 0.0), workers: $m.workers, grain: $m.grain, masks: null, witness: $witness }
    let b = (gauge measure screen-frame $measured $stamp ($placed | get 1) $expect)
    { stamp: $stamp, from: ($placed | get 1), frame: $b.frame, problems: $b.problems }
}

# A launch's row: status, screen, frame line, faults, and binding
def row-of [run: record, p: record, m: record, cancel: bool]: nothing -> record {
    let lines = ($run.serial | lines)
    let frames = ($lines | where {|l| $l starts-with "fps: frame in" })
    let last = (if ($frames | is-empty) { null } else { $frames | last | parse $FRAME | get -o 0 | update cells {|c| $c | into int } })
    {
        pose: $p.name, workers: $m.workers, grain: $m.grain, status: $run.status, screen: $run.screen,
        hash: (if $run.screen != "" { open --raw $run.screen | hash sha256 } else { null }),
        frame: $last, faults: ($lines | where {|l| ($l starts-with "jab: ") and (($l =~ "fault") or ($l =~ "shutdown")) }),
        workers_line: ($lines | where {|l| $l starts-with "fps: workers" } | get -o 0), frames: ($frames | length),
        binding: (bind $run $p $m $cancel),
    }
}

# A still copy's views drawn by each mode and judged against W 0's
export def main [kernel: path, image: path, out: path, --set: string = "debug", --poses: string = "spawn,bay,up", --modes: string = "0:0,2:0,1:0,2:16", --map: string = "render_0", --harts: int = 4, --bootargs: string = "", --cancel] {
    let wanted = ($poses | split row ",")
    let modes = (modes-of $modes)
    let poses = (poses-all | where {|x| $x.name in $wanted })
    if ($poses | is-empty) { error make { msg: $"no pose named among ($wanted | str join ', ')" } }
    let disk = (disk-of $map $out)
    mut rows = []
    for p in $poses {
        for m in $modes {
            let label = $"($p.name)_w($m.workers)_g($m.grain)"
            let run = (launch --kernel $kernel --image $image --out ($out | path join $label) --set $set --sound --api --disk $disk.disk --serial "fps" --send (sends-of $p $m $cancel $SCREEN_AT) --screen $SCREEN_AT --seconds $SECONDS --harts $harts --bootargs $bootargs)
            let row = (row-of $run $p $m $cancel)
            $rows = ($rows | append $row)
            let b = $row.binding
            print $"($label): status ($row.status), stamp ($b.stamp | default 'none'), frame ($b.frame | default 'none') of the window from ($b.from | default 'none'), (if ($b.problems | is-empty) { 'bound' } else { $'unbound: ($b.problems | str join "; ")' }), frames ($row.frames), ($row.workers_line | default 'no workers line'), faults ($row.faults | length)"
        }
    }
    let parity = { disk: $disk, rows: $rows }
    $parity | to nuon | save -f ($out | path join "parity.nuon")
    judge $parity $out $cancel $harts $bootargs
}

# A parity's launches judged against each pose's W 0, verdict.nuon kept
def judge [parity: record, out: path, cancel: bool, harts: int, bootargs: string] {
    mut verdicts = []
    for p in ($parity.rows | get pose | uniq) {
        let set = ($parity.rows | where pose == $p)
        let base = ($set | where workers == 0 | get -o 0)
        let held = ($base != null and ($base.binding.problems | is-empty) and $base.status == $BOUND_STATUS and ($base.faults | is-empty) and $base.frame != null and $base.frame.workers == 0)
        if $base != null {
            $verdicts = ($verdicts | append { pose: $p, workers: 0, grain: $base.grain, control: true, binding: $base.binding, status: $base.status, faults: ($base.faults | length), ok: $held })
            print $"($p) w0 g($base.grain): the control (if $held { 'held' } else { $'not held: binding ($base.binding.problems | str join "; "), status ($base.status), faults ($base.faults | length)' })"
        }
        let base_bytes = (if $held { open --raw $base.screen | into binary } else { null })
        for r in ($set | where workers != 0) {
            let bound = ($r.binding.problems | is-empty)
            let differing = (if $base_bytes == null or $r.screen == "" { null } else { picture unstamped-differ (open --raw $r.screen | into binary) $base_bytes })
            let same = ($differing != null and ($differing | is-empty))
            let differ = (if $base == null or $base.frame == null or $r.frame == null { ["no frame"] } else {
                $COUNTS | where {|c| ($base.frame | get $c) != ($r.frame | get $c) }
            })
            let drawn = ($r.frame != null and $r.frame.workers == $r.workers and $r.frame.grain == $r.grain)
            let cancelled = (not $cancel) or ($r.frame != null and $r.frame.rounds > 0 and $r.frame.cancelled == $r.frame.rounds)
            let ok = ($bound and $same and ($differ | is-empty) and $drawn and $cancelled and $r.status == $BOUND_STATUS and ($r.faults | is-empty))
            $verdicts = ($verdicts | append { pose: $p, workers: $r.workers, grain: $r.grain, control: false, binding: $r.binding, capture: $same, rows_differing: ($differing | default [] | length), counts: ($differ | is-empty), drawn: $drawn, cancelled: $cancelled, status: $r.status, faults: ($r.faults | length), ok: $ok, differ: $differ })
            let f = $r.frame
            let w = (if $f == null { "" } else { $"workers ($f.workers) grain ($f.grain) rounds ($f.rounds) cancelled ($f.cancelled) bands (1..$GFX_SLOTS | each {|h| $f | get $'bands($h)' } | str join ' ') raster ($f.raster_us)" })
            let capture = (if $differing == null { "no bound control to compare" } else if $same { "equal to w0's, the stamp's cells skipped" } else { $"differs from w0's in ($differing | length) rows" })
            print $"($p) w($r.workers) g($r.grain): (if $bound { 'bound' } else { $'unbound: ($r.binding.problems | str join "; ")' }); capture ($capture); (if ($differ | is-empty) { 'counts equal' } else { $'counts differ: ($differ | str join ", ")' }); ($w)"
        }
    }
    let ok = (($verdicts | length) > 0 and ($verdicts | all {|v| $v.ok }))
    { ok: $ok, cancel: $cancel, harts: $harts, bootargs: $bootargs, disk: $parity.disk, judged: ($verdicts | length), failed: ($verdicts | where {|v| not $v.ok } | length), verdicts: $verdicts } | to nuon --indent 2 | save -f ($out | path join "verdict.nuon")
    print $"workerparity: (if $ok { 'ok' } else { 'failed' }), ($verdicts | length) judged, ($verdicts | where {|v| not $v.ok } | length) failed"
}

# A parity judged again from its recorded launches, the old verdict kept
export def rejudge [out: path, --cancel, --harts: int = 4, --bootargs: string = ""] {
    let before = ($out | path join "verdict_before.nuon")
    if ($before | path exists) { error make { msg: $"($before) exists; a parity is judged again once" } }
    let parity = (open ($out | path join "parity.nuon"))
    if not (($parity | describe) starts-with "record") { error make { msg: $"($out)'s parity.nuon predates the picture contract: rows with no bindings and no disk" } }
    let verdict = ($out | path join "verdict.nuon")
    if ($verdict | path exists) { mv $verdict $before }
    judge $parity $out $cancel $harts $bootargs
}

# A worker's fault at each count, the run ended through the kernel
export def fault [kernel: path, image: path, out: path, --set: string = "debug", --pose: string = "spawn", --modes: string = "1:0,2:0,3:0,4:0,5:0,6:0,7:0", --map: string = "render_0", --harts: int = 8, --bootargs: string = "", --started: string = ""] {
    let modes = (modes-of $modes | where workers > 0)
    let harts_started = (if $started == "" { 1..<$harts | each {|h| $h } } else { $started | split row "," | each {|h| $h | into int } })
    let p = (poses-all | where name == $pose | get 0)
    let disk = (disk-of $map $out)
    mut verdicts = []
    for m in $modes {
        let hart = ($harts_started | get ($m.workers - 1))
        let label = $"fault_w($m.workers)_g($m.grain)_h($hart)"
        let sends = [
            { at: 200ms, bytes: (workers-frame $m.workers $m.grain) }
            { at: 1900ms, bytes: (pose command-frame "L") }
            { at: 2000ms, bytes: (pose pose-frame $p) }
            { at: 3000ms, bytes: (jobs-frame false $hart) }
        ]
        let run = (launch --kernel $kernel --image $image --out ($out | path join $label) --set $set --sound --api --disk $disk.disk --serial "fps" --send $sends --seconds 9 --harts $harts --bootargs $bootargs)
        let lines = ($run.serial | lines)
        let faults = ($lines | where {|l| $l starts-with "jab: worker fault: " })
        let named = (($faults | length) == 1 and ($faults | get 0 | str starts-with $"jab: worker fault: hart=($hart) "))
        let answered = (answered-frames $run.api $CONSOLE_J)
        let s = (gauge stream $run.api)
        let at = ($answered | get -o 0)
        let after = (if $at == null { -1 } else { ($s.frames | where frame >= $at | length) + ($s.presents | where frame >= $at | length) })
        let ok = ($named and $run.status == 1 and $at != null and $after == 0)
        $verdicts = ($verdicts | append { workers: $m.workers, grain: $m.grain, hart: $hart, status: $run.status, faults: $faults, answered: $at, recorded_after: $after, ok: $ok })
        print $"($label): status ($run.status), ($faults | get -o 0 | default 'no fault line' | str substring 0..60), J read at frame ($at | default 'none'), ($after) records at or after it"
    }
    let ok = (($verdicts | length) > 0 and ($verdicts | all {|v| $v.ok }))
    { ok: $ok, harts: $harts, bootargs: $bootargs, disk: $disk, judged: ($verdicts | length), failed: ($verdicts | where {|v| not $v.ok } | length), verdicts: $verdicts } | to nuon --indent 2 | save -f ($out | path join "verdict.nuon")
    print $"workerparity fault: (if $ok { 'ok' } else { 'failed' }), ($verdicts | length) judged"
}
