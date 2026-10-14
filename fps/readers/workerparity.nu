# workerparity.nu: the still copy's settled views drawn by the serial backend and by
# workers, the captures hashed and the frame lines' counts compared; with
# --cancel every round cancelled through the J frame; `fault` a worker's
# fault on the highest active hart at each count
use ../../../jab/sdk/nu/jab.nu
use ../../../jab/game/fps/test/pose.nu
use ../../../jab/game/fps/test/gauge.nu

# the game's directory, jab checked out beside this repository
const GAME = (path self | path dirname | path join .. .. .. jab game fps)

# the frame line, its bands a count a hart, harts 1 to GFX_SLOTS
const FRAME = "fps: frame in {us} us: {sectors} sectors, {walls} walls, {pieces} pieces, {planes} planes, {openings} openings, {sprites} sprites, {uncovered} uncovered; clear, planes, walls, portals, sprites, raster us {clear}, {plane_us}, {wall_us}, {portal_us}, {sprite_us}, {raster_us}; spans {spans}, pixels {pixels}, lit spans {lit_spans}, lit pixels {lit_pixels}, light us {light_us}, rejected {rejected}, samples {samples}, tiles built {tiles_built}, tiled {tiled}, resets {resets}, slots {slots}, commands {commands}, flushes {flushes}, workers {workers}, grain {grain}, rounds {rounds}, bands {bands1} {bands2} {bands3} {bands4} {bands5} {bands6} {bands7}, dispatch us {dispatch}, barrier us {barrier}, slowest us {slowest}, busy us {busy}, cancelled {cancelled}"
# the drawing's counts judged against W 0's; the pool's slots in use are
# recorded and left unjudged, since how many frame boundaries fall between
# the L's forget and the pose decides which start-view tiles the pool keeps
# beside the pose's: garage on the sparse grant read 167 and 439 for one
# mode in two runs alone, every capture and drawing count alike
const COUNTS = [spans pixels lit_spans lit_pixels rejected samples tiled commands flushes uncovered]
# render.inc's GFX_SLOTS, the W frame's greatest count
const GFX_SLOTS = 7
# an API record's bytes, the state record's kind, and render.inc's
# REPORT_CONSOLE, a console answer's kind, its command's byte at 4
const RECORD = 64
const STATE_KIND = 1
const CONSOLE_KIND = 11
const CONSOLE_J = 74

export def workers-frame [workers: int, grain: int]: nothing -> binary {
    [("W" | into binary), 0x[00 00 00], ($workers | into binary | bytes at 0..<1), 0x[00 00 00], ($grain | into binary | bytes at 0..<4), (0..<52 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The console's J frame, a debug build's: byte 12 set cancels every round
# after its publish while it stands; byte 13 the hart whose worker faults
# on its next round, 0 for none.
export def jobs-frame [cancel: bool, fault: int]: nothing -> binary {
    [("J" | into binary), 0x[00 00 00], 0x[00], 0x[00 00 00], 0x[00 00 00 00], (if $cancel { 0x[01] } else { 0x[00] }), ($fault | into binary | bytes at 0..<1), 0x[00], (0..<49 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The frames that read a console command, each the count of state records
# before its answer, so the frame's own state is the next one.
def answered-frames [api: binary, command: int]: nothing -> list<int> {
    mut states = 0
    mut frames = []
    for r in ($api | chunks $RECORD | where {|c| ($c | bytes length) == $RECORD }) {
        let kind = ($r | bytes at 0..<4 | into int --endian little)
        if $kind == $STATE_KIND { $states += 1 }
        if $kind == $CONSOLE_KIND and ($r | bytes at 4..<8 | into int --endian little) == $command { $frames = ($frames | append $states) }
    }
    $frames
}

def poses-all []: nothing -> list<any> {
    [
        { name: r1_spawn, x: 4.0, y: 4.0, z: 1.6, yaw: 0, pitch: 0 }
        { name: r1_window, x: 5.0, y: 4.0, z: 4.85, yaw: 0, pitch: -20 }
        { name: r1_grate, x: 9.0, y: 11.0, z: 1.6, yaw: 0, pitch: 0 }
        { name: r1_landing, x: 12.0, y: 4.0, z: 3.1, yaw: 90, pitch: 10 }
        { name: r1_ramp, x: 12.0, y: 6.5, z: 3.94, yaw: 90, pitch: -30 }
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

def modes-of [modes: string]: nothing -> list<any> {
    let parsed = ($modes | split row "," | each {|m| let p = ($m | split row ":"); { workers: ($p.0 | into int), grain: ($p.1 | into int) } })
    let outside = ($parsed | where {|m| $m.workers < 0 or $m.workers > $GFX_SLOTS })
    if not ($outside | is-empty) { error make { msg: $"a mode's workers run 0 to ($GFX_SLOTS): ($outside | to nuon)" } }
    $parsed
}

def disk-of [map: string, out: path]: nothing -> string {
    let tree = (jab program-shard $GAME "asset" | path join $map)
    mkdir $out
    let disk = ($out | path join $"($map).romfs")
    let made = (^genromfs -d $tree -f $disk -V "fps" | complete)
    if $made.exit_code != 0 { error make { msg: $"genromfs: ($made.stderr)" } }
    $disk
}

# Each pose and mode a launch, the W at 200 ms (with --cancel the J's
# cancel beside it), the L at 1900, the pose at 2000 and 8000, the capture
# at 9000; each capture's SHA-256 and frame line against W 0's of the same
# pose, every round cancelled under --cancel. parity.nuon holds every
# launch's row, verdict.nuon each non-W-0 row judged and `ok`.
def main [kernel: path, image: path, out: path, --set: string = "debug", --poses: string = "spawn,bay,up", --modes: string = "0:0,2:0,1:0,2:16", --map: string = "render_0_still", --harts: int = 4, --bootargs: string = "", --cancel] {
    let wanted = ($poses | split row ",")
    let modes = (modes-of $modes)
    let disk = (disk-of $map $out)
    let lframe = (pose command-frame "L")
    mut rows = []
    for p in (poses-all | where {|x| $x.name in $wanted }) {
        for m in $modes {
            let label = $"($p.name)_w($m.workers)_g($m.grain)"
            let run_out = ($out | path join $label)
            let cancels = (if $cancel { [{ at: 200ms, bytes: (jobs-frame true 0) }] } else { [] })
            let sends = ([{ at: 200ms, bytes: (workers-frame $m.workers $m.grain) }] ++ $cancels ++ [
                { at: 1900ms, bytes: $lframe }
                { at: 2000ms, bytes: (pose pose-frame $p) }
                { at: 8000ms, bytes: (pose pose-frame $p) }
            ])
            let run = (jab launch --kernel $kernel --image $image --out $run_out --set $set --sound --api --disk $disk --serial "fps" --send $sends --capture 9000ms --seconds 11 --harts $harts --bootargs $bootargs)
            let lines = ($run.serial | lines)
            let frames = ($lines | where {|l| $l starts-with "fps: frame in" })
            let last = (if ($frames | is-empty) { null } else { $frames | last | parse $FRAME | get -o 0 | update cells {|c| $c | into int } })
            let faults = ($lines | where {|l| ($l starts-with "jab: ") and (($l =~ "fault") or ($l =~ "shutdown")) })
            let workers_line = ($lines | where {|l| $l starts-with "fps: workers" } | get -o 0)
            let hash = (if $run.screen != "" { open --raw $run.screen | hash sha256 } else { null })
            $rows = ($rows | append {
                pose: $p.name, workers: $m.workers, grain: $m.grain, status: $run.status, hash: $hash,
                frame: $last, faults: $faults, workers_line: $workers_line, frames: ($frames | length),
            })
            print $"($label): status ($run.status), hash ($hash | default 'none' | str substring 0..16), frames ($frames | length), ($workers_line | default 'no workers line'), faults ($faults | length)"
        }
    }
    $rows | to nuon | save -f ($out | path join "parity.nuon")
    judge $rows $out $cancel $harts $bootargs
}

# A parity's runs judged against W 0's of their pose: the capture, the
# drawing's counts (COUNTS), the workers and grain drawn, every round
# cancelled under `cancel`, and no fault; verdict.nuon written.
def judge [rows: list<any>, out: path, cancel: bool, harts: int, bootargs: string] {
    mut verdicts = []
    for p in ($rows | get pose | uniq) {
        let set = ($rows | where pose == $p)
        let base = ($set | where workers == 0 | get -o 0)
        for r in ($set | where workers != 0) {
            let same = ($base != null and $base.hash != null and $r.hash == $base.hash)
            let differ = (if $base == null or $base.frame == null or $r.frame == null { ["no frame"] } else {
                $COUNTS | where {|c| ($base.frame | get $c) != ($r.frame | get $c) }
            })
            let drawn = ($r.frame != null and $r.frame.workers == $r.workers and $r.frame.grain == $r.grain)
            let cancelled = (not $cancel) or ($r.frame != null and $r.frame.rounds > 0 and $r.frame.cancelled == $r.frame.rounds)
            let ok = ($same and ($differ | is-empty) and $drawn and $cancelled and ($r.faults | is-empty))
            $verdicts = ($verdicts | append { pose: $p, workers: $r.workers, grain: $r.grain, capture: $same, counts: ($differ | is-empty), drawn: $drawn, cancelled: $cancelled, faults: ($r.faults | length), ok: $ok, differ: $differ })
            let f = $r.frame
            let w = (if $f == null { "" } else { $"workers ($f.workers) grain ($f.grain) rounds ($f.rounds) cancelled ($f.cancelled) bands (1..$GFX_SLOTS | each {|h| $f | get $'bands($h)' } | str join ' ') raster ($f.raster_us)" })
            print $"($p) w($r.workers) g($r.grain): capture (if $same { 'equal' } else { 'differs' }) to w0; (if ($differ | is-empty) { 'counts equal' } else { $'counts differ: ($differ | str join ", ")' }); ($w)"
        }
    }
    let ok = (($verdicts | length) > 0 and ($verdicts | all {|v| $v.ok }))
    { ok: $ok, cancel: $cancel, harts: $harts, bootargs: $bootargs, judged: ($verdicts | length), failed: ($verdicts | where {|v| not $v.ok } | length), verdicts: $verdicts } | to nuon --indent 2 | save -f ($out | path join "verdict.nuon")
    print $"workerparity: (if $ok { 'ok' } else { 'failed' }), ($verdicts | length) judged, ($verdicts | where {|v| not $v.ok } | length) failed"
}

# A parity judged again from its recorded rows, as when the judged counts
# change: the verdict before kept as verdict_before.nuon, written once.
def "main judge" [out: path, --cancel, --harts: int = 4, --bootargs: string = ""] {
    let before = ($out | path join "verdict_before.nuon")
    if ($before | path exists) { error make { msg: $"($before) exists; a parity is judged again once" } }
    let verdict = ($out | path join "verdict.nuon")
    if ($verdict | path exists) { mv $verdict $before }
    judge (open ($out | path join "parity.nuon")) $out $cancel $harts $bootargs
}

# A worker's fault at each count: the W at 200 ms, the L at 1900, the pose
# at 2000, the J naming the highest active hart at 3000, the W's lowest
# harts of those started (`--started`, harts 1 up by default); the run ends
# through the kernel with that hart's fault line alone and status 1, and no
# frame at or past the one that read the J records a frame or a
# presentation, so nothing was flipped after the fault. verdict.nuon holds
# each count judged and `ok`.
def "main fault" [kernel: path, image: path, out: path, --set: string = "debug", --pose: string = "spawn", --modes: string = "1:0,2:0,3:0,4:0,5:0,6:0,7:0", --map: string = "render_0_still", --harts: int = 8, --bootargs: string = "", --started: string = ""] {
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
        let run = (jab launch --kernel $kernel --image $image --out ($out | path join $label) --set $set --sound --api --disk $disk --serial "fps" --send $sends --seconds 9 --harts $harts --bootargs $bootargs)
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
    { ok: $ok, harts: $harts, bootargs: $bootargs, judged: ($verdicts | length), failed: ($verdicts | where {|v| not $v.ok } | length), verdicts: $verdicts } | to nuon --indent 2 | save -f ($out | path join "verdict.nuon")
    print $"workerparity fault: (if $ok { 'ok' } else { 'failed' }), ($verdicts | length) judged"
}
