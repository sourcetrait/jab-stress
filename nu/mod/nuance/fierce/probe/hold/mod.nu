use (path self ../../../../../../../jab/nu/mod/launch)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/pose)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/console)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../fierce/places)

# When the W and the J are sent
const SET_AT = 1300ms

# When the E closes the run's measurement
const END_AT = 3500ms

# The console's J frame: a worker delayed, cancelled, faulted, or held
def jobs-frame [delayed: int, delay_us: int, cancel: bool, fault: int, --hold]: nothing -> binary {
    [("J" | into binary), 0x[00 00 00], ($delayed | into binary | bytes at 0..<1), 0x[00 00 00], ($delay_us | into binary | bytes at 0..<4), (if $cancel { 0x[01] } else { 0x[00] }), ($fault | into binary | bytes at 0..<1), (if $hold { 0x[01] } else { 0x[00] }), (0..<49 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# W 2 in fixed bands with worker 2 held to the join, or unheld, read back
export def main [kernel: path, image: path, disk: path, out: path, --name: string = "hold", --no-hold, --seconds: int = 8, --no-capture]: nothing -> nothing {
    let sends = [
        { at: $SET_AT, bytes: (console workers 2 0) }
        { at: $SET_AT, bytes: (jobs-frame 2 0 false 0 --hold=(not $no_hold)) }
        { at: $END_AT, bytes: (pose command-frame "E") }
    ]
    let capture = (if $no_capture { 0sec } else { $END_AT + 500ms })
    let run = (launch --kernel $kernel --image $image --out ($out | path join $name) --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --capture $capture --seconds $seconds)
    let lines = ($run.serial | lines | where {|l| $l starts-with 'fps: ' })
    let said = ($lines | where {|l| ($l =~ 'never released') or ($l =~ 'before the round joined') or ($l =~ 'unjoined') or ($l =~ 'lost bands') })
    let packets = (try { (gauge stream $run.api).packets } catch { [] })
    let rounds = ($packets | where {|p| ($p.workers | default 0) == 2 and ($p.grain | default 1) == 0 and ($p.busy_us | default 0) > 0 })
    let share = ($rounds | each {|p| (($p.slowest_us * 100) // $p.busy_us) })
    let summary = {
        name: $name, held: (not $no_hold), status: $run.status, wall_seconds: $run.wall_seconds, screen: ($run.screen != ""), said: $said,
        exit_line: ($run.debug | lines | where {|l| $l starts-with 'jab: exit' } | get -o 0),
        rounds: ($rounds | length),
        slowest_share_pct: (if ($share | is-empty) { null } else { { min: ($share | math min), median: ($share | math median), max: ($share | math max) } }),
        last_lines: ($lines | last 3),
    }
    $summary | to nuon | save -f ($out | path join $"($name).nuon")
    print ($summary | to nuon)
}

# The hold on jab's debug tree, or on another image beside its kernel and disk
export def on-debug [out: path, --image: string = "", --name: string = "hold", --no-hold, --seconds: int = 8, --no-capture]: nothing -> nothing {
    let p = (places)
    main $p.kernel (if $image == "" { $p.image } else { $image }) $p.disk $out --name $name --no-hold=$no_hold --seconds $seconds --no-capture=$no_capture
}
