# workerparity.nu: the still copy's settled views drawn by the serial backend and by
# workers, the captures hashed and the frame lines' counts compared
use ../../../jab/sdk/nu/jab.nu
use ../../../jab/game/fps/test/pose.nu

# the game's directory, jab checked out beside this repository
const GAME = (path self | path dirname | path join .. .. .. jab game fps)

const FRAME = "fps: frame in {us} us: {sectors} sectors, {walls} walls, {pieces} pieces, {planes} planes, {openings} openings, {sprites} sprites, {uncovered} uncovered; clear, planes, walls, portals, sprites, raster us {clear}, {plane_us}, {wall_us}, {portal_us}, {sprite_us}, {raster_us}; spans {spans}, pixels {pixels}, lit spans {lit_spans}, lit pixels {lit_pixels}, light us {light_us}, rejected {rejected}, samples {samples}, tiles built {tiles_built}, tiled {tiled}, resets {resets}, slots {slots}, commands {commands}, flushes {flushes}, workers {workers}, grain {grain}, rounds {rounds}, bands {bands0} {bands1}, dispatch us {dispatch}, barrier us {barrier}, slowest us {slowest}, busy us {busy}, cancelled {cancelled}"
const COUNTS = [spans pixels lit_spans lit_pixels rejected samples tiled slots commands flushes uncovered]

export def workers-frame [workers: int, grain: int]: nothing -> binary {
    [("W" | into binary), 0x[00 00 00], ($workers | into binary | bytes at 0..<1), 0x[00 00 00], ($grain | into binary | bytes at 0..<4), (0..<52 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def main [kernel: path, image: path, out: path, --set: string = "debug", --poses: string = "spawn,bay,up", --modes: string = "0:0,2:0,1:0,2:16", --map: string = "render_0_still", --harts: int = 4] {
    let render_1 = [
        { name: r1_spawn, x: 4.0, y: 4.0, z: 1.6, yaw: 0, pitch: 0 }
        { name: r1_window, x: 5.0, y: 4.0, z: 4.85, yaw: 0, pitch: -20 }
        { name: r1_grate, x: 9.0, y: 11.0, z: 1.6, yaw: 0, pitch: 0 }
        { name: r1_landing, x: 12.0, y: 4.0, z: 3.1, yaw: 90, pitch: 10 }
        { name: r1_ramp, x: 12.0, y: 6.5, z: 3.94, yaw: 90, pitch: -30 }
        { name: r1_door, x: 4.0, y: 5.0, z: 1.6, yaw: 90, pitch: 0 }
        { name: r1_light, x: 4.0, y: 4.0, z: 1.6, yaw: 180, pitch: -45 }
    ]
    let all = $render_1 ++ [
        { name: spawn, x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }
        { name: yard, x: 40.0, y: 6.0, z: 1.6, yaw: 90, pitch: 10 }
        { name: window, x: 8.75, y: 17.0, z: 4.6, yaw: 0, pitch: -15 }
        { name: bay, x: 20.0, y: 17.0, z: 1.6, yaw: 180, pitch: 5 }
        { name: up, x: 8.75, y: 3.5, z: 1.6, yaw: 90, pitch: 15 }
        { name: down, x: 1.5, y: 3.5, z: 1.6, yaw: 90, pitch: -15 }
        { name: garage, x: 16.0, y: 14.0, z: -1.4, yaw: 0, pitch: 0 }
    ]
    let wanted = ($poses | split row ",")
    let modes = ($modes | split row "," | each {|m| let p = ($m | split row ":"); { workers: ($p.0 | into int), grain: ($p.1 | into int) } })
    let game = $GAME
    let tree = (jab program-shard $game "asset" | path join $map)
    mkdir $out
    let disk = ($out | path join $"($map).romfs")
    let made = (^genromfs -d $tree -f $disk -V "fps" | complete)
    if $made.exit_code != 0 { error make { msg: $"genromfs: ($made.stderr)" } }
    let lframe = (pose command-frame "L")
    mut rows = []
    for p in ($all | where {|x| $x.name in $wanted }) {
        for m in $modes {
            let label = $"($p.name)_w($m.workers)_g($m.grain)"
            let run_out = ($out | path join $label)
            let sends = [
                { at: 200ms, bytes: (workers-frame $m.workers $m.grain) }
                { at: 1900ms, bytes: $lframe }
                { at: 2000ms, bytes: (pose pose-frame $p) }
                { at: 8000ms, bytes: (pose pose-frame $p) }
            ]
            let run = (jab launch --kernel $kernel --image $image --out $run_out --set $set --sound --api --disk $disk --serial "fps" --send $sends --capture 9000ms --seconds 11 --harts $harts)
            let lines = ($run.serial | lines)
            let frames = ($lines | where {|l| $l starts-with "fps: frame in" })
            let last = (if ($frames | is-empty) { null } else { $frames | last | parse $FRAME | get -o 0 })
            let faults = ($lines | where {|l| $l starts-with "jab: " })
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
    for p in ($rows | get pose | uniq) {
        let set = ($rows | where pose == $p)
        let base = ($set | where workers == 0 | get -o 0)
        for r in ($set | where workers != 0) {
            let same = ($base != null and $r.hash == $base.hash)
            let counts = (if $base == null or $base.frame == null or $r.frame == null { "no frame" } else {
                let diffs = ($COUNTS | where {|c| ($base.frame | get $c) != ($r.frame | get $c) })
                if ($diffs | is-empty) { "counts equal" } else { $"counts differ: ($diffs | each {|c| $'($c) ($base.frame | get $c) vs ($r.frame | get $c)' } | str join '; ')" }
            })
            let f = $r.frame
            let w = (if $f == null { "" } else { $"workers ($f.workers) grain ($f.grain) rounds ($f.rounds) bands ($f.bands0) ($f.bands1) dispatch ($f.dispatch) barrier ($f.barrier) slowest ($f.slowest) busy ($f.busy) raster ($f.raster_us) clear ($f.clear)" })
            print $"($p) w($r.workers) g($r.grain): capture (if $same { 'equal' } else { 'differs' }) to w0; ($counts); ($w)"
        }
        if $base != null and $base.frame != null { print $"($p) w0: raster ($base.frame.raster_us) clear ($base.frame.clear) workers ($base.frame.workers)" }
    }
}
