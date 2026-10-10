# All-lit identity (IntervalPhase): the held-off views of the handoff's
# wall, head-on at levels 0 to 6 and oblique at 0 to 2 under the gradient
# and the parity, and of the still copy's spawn view and its two view
# yaws under the room's light, each drawn by two debug images and held
# byte for byte, unstamped.
use ../../../../jab/sdk/nu/jab.nu
use ../../../../jab/game/fps/test/pose.nu

def level-frame [bright: bool, held: bool, --parity, --gradient]: nothing -> binary {
    let flag = {|on: bool| if $on { 0x[01] } else { 0x[00] } }
    [("L" | into binary), 0x[00 00 00], (do $flag $bright), (do $flag $held), (do $flag $gradient), (do $flag $parity), (0..<56 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def raise-frame [levels: int]: nothing -> binary {
    [("M" | into binary), 0x[00 00 00], ($levels | into binary | bytes at 0..<1), (0..<59 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

def main [kernel: path, base: path, new: path, handoff_disk: path, still_disk: path, out: path] {
    let head = { name: "head", x: 6.5, y: 9.5, z: 1.6, yaw: 90, pitch: 0 }
    let oblique = { name: "oblique", x: 11.02, y: 11.5, z: 1.6, yaw: 135, pitch: 0 }
    let light = {|lighting: string| if $lighting == "gradient" { level-frame false true --gradient } else { level-frame false true --parity } }
    let wall = ([gradient parity] | each {|lighting|
        (0..6 | each {|l| { name: $"head_($lighting)_($l)", pose: $head, disk: $handoff_disk, sends: [{ at: 1400ms, bytes: (do $light $lighting) }, { at: 1400ms, bytes: (raise-frame $l) }] } })
        | append (0..2 | each {|l| { name: $"oblique_($lighting)_($l)", pose: $oblique, disk: $handoff_disk, sends: [{ at: 1400ms, bytes: (do $light $lighting) }, { at: 1400ms, bytes: (raise-frame $l) }] } })
    } | flatten)
    let still = ([
        { name: "spawn", x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }
        { name: "view170", x: 29.0, y: 2.5, z: 1.6, yaw: 170, pitch: 0 }
        { name: "view130", x: 29.0, y: 2.5, z: 1.6, yaw: 130, pitch: 0 }
    ] | each {|p| { name: $"still_($p.name)", pose: $p, disk: $still_disk, sends: [{ at: 1400ms, bytes: (level-frame false true) }] } })
    let rows = ($wall | append $still | each {|c|
        let shots = ([[image tag]; [$base base] [$new new]] | each {|i|
            let placed = (pose pose-frame $c.pose)
            let all = ($c.sends | append [{ at: 1500ms, bytes: $placed }, { at: 2300ms, bytes: $placed }] | sort-by at)
            let run = (jab launch --kernel $kernel --image $i.image --out ($out | path join $"($c.name)_($i.tag)") --set DEBUG --sound --api --disk $c.disk --serial "fps" --send $all --capture 3500ms --seconds 5)
            { screen: $run.screen, frames: ($run.serial | lines | where {|l| $l starts-with "fps: frame in" } | length) }
        })
        let a = (if ($shots.0.screen == "") { 0x[] } else { open --raw $shots.0.screen | into binary })
        let b = (if ($shots.1.screen == "") { 0x[] } else { open --raw $shots.1.screen | into binary })
        { name: $c.name, both: (($a | bytes length) > 0 and ($b | bytes length) > 0), same: ($a == $b), frames: ($shots | get frames | str join "/") }
    })
    $rows | to nuon | save -f ($out | path join "identity.nuon")
    print ($rows | to nuon)
}
