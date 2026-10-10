# JoinBeforeBoundary's probe: the still disk's spawn view drawn by W 2 in
# fixed bands, one band a worker, with the J frame holding worker 2,
# mailbox index 1, until the round's join releases it (byte 14), or with
# `--no-hold` the same run unheld. Read back: the guest's status, the
# UART's fps lines, and the frames' rounds after the J, each round's
# slowest worker against every worker's busy time: a held round's
# slowest is about the whole of it, since the held worker's band waits
# on the other's join, where an unheld round's is about half.
use ../../../../jab/sdk/nu/jab.nu
use ../../../../jab/game/fps/test/pose.nu
use ../../../../jab/game/fps/test/gauge.nu

const SET_AT = 1300ms
const END_AT = 3500ms

# The console's J frame: the delayed worker's index plus one in byte 4,
# its delay in microseconds from byte 8, the cancel in byte 12, the
# faulting worker in byte 13, and the hold in byte 14.
def jobs-frame [delayed: int, delay_us: int, cancel: bool, fault: int, --hold]: nothing -> binary {
    [("J" | into binary), 0x[00 00 00], ($delayed | into binary | bytes at 0..<1), 0x[00 00 00], ($delay_us | into binary | bytes at 0..<4), (if $cancel { 0x[01] } else { 0x[00] }), ($fault | into binary | bytes at 0..<1), (if $hold { 0x[01] } else { 0x[00] }), (0..<49 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def main [kernel: path, image: path, disk: path, out: path, --name: string = "hold", --no-hold, --seconds: int = 8] {
    let sends = [
        { at: $SET_AT, bytes: (gauge workers-frame 2 0) }
        { at: $SET_AT, bytes: (jobs-frame 2 0 false 0 --hold=(not $no_hold)) }
        { at: $END_AT, bytes: (pose command-frame "E") }
    ]
    let run = (jab launch --kernel $kernel --image $image --out ($out | path join $name) --set DEBUG --sound --api --disk $disk --serial "fps" --send $sends --capture ($END_AT + 500ms) --seconds $seconds)
    let lines = ($run.serial | lines | where {|l| $l starts-with 'fps: ' })
    let said = ($lines | where {|l| ($l =~ 'never released') or ($l =~ 'before the round joined') or ($l =~ 'unjoined') or ($l =~ 'lost bands') })
    let packets = (try { (gauge stream $run.api).packets } catch { [] })
    let rounds = ($packets | where {|p| ($p.workers | default 0) == 2 and ($p.grain | default 1) == 0 and ($p.busy_us | default 0) > 0 })
    let share = ($rounds | each {|p| (($p.slowest_us * 100) // $p.busy_us) })
    let summary = {
        name: $name, held: (not $no_hold), status: $run.status, said: $said,
        rounds: ($rounds | length),
        slowest_share_pct: (if ($share | is-empty) { null } else { { min: ($share | math min), median: ($share | math median), max: ($share | math max) } }),
        last_lines: ($lines | last 3),
    }
    $summary | to nuon | save -f ($out | path join $"($name).nuon")
    print ($summary | to nuon)
}
