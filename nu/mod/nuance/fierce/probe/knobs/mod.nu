use (path self ../../../../../../../jab/nu/mod/target)
use (path self ../../../../../../../jab/nu/mod/launch)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/pose)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/console)
use (path self ../../../../../../../jab/kit/fierce/nu/mod/gauge)

# The still copy's spawn view
const SPAWN_POSE = { name: "spawn", x: 29.0, y: 2.5, z: 1.6, yaw: 150, pitch: 0 }

# jab, checked out beside the workbench
const JAB = (path self ../../../../../../../jab | path expand)

# The console's K frame: a packet's commands and spans
def packet-frame [commands: int, spans: int]: nothing -> binary {
    let word = {|v: int| $v | into binary | bytes at 0..<4 }
    [("K" | into binary), 0x[00 00 00], (do $word $commands), (do $word $spans), (0..<52 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The console's O frame with its trace, guarantee, ring, and merge
def pool-frame [--modes: int = 0, --trace, --cold, --slots: int = 0, --guarantee: int = 0, --ring: int = 0, --merge-us: int = 0]: nothing -> binary {
    let word = {|v: int| $v | into binary | bytes at 0..<4 }
    let flag = {|on: bool| if $on { 0x[01] } else { 0x[00] } }
    [("O" | into binary), 0x[00 00 00], ($modes | into binary | bytes at 0..<1), (do $flag $trace), (do $flag $cold), 0x[00], (do $word $slots), (do $word $guarantee), (do $word $ring), (do $word $merge_us), (0..<40 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# The pool's traced passes a frame, read from a run's UART
def pool-trace [serial: string]: nothing -> table<frame: int, requesting: list<int>, merged: list<record<surface: int, keys: int>>, built: list<int>> {
    let parsed = ($serial | lines | where {|l| $l starts-with "fps: tile pass " } | parse "fps: tile pass {frame} {kind}:{items}" | update frame {|r| $r.frame | into int })
    $parsed | group-by frame | items {|frame, rows|
        let of = {|kind: string| $rows | where kind == $kind | get items | each {|i| $i | str trim | split row " " | where {|w| $w != "" } } | flatten }
        {
            frame: ($frame | into int),
            requesting: (do $of "requesting" | each {|w| $w | into int }),
            merged: (do $of "merged" | each {|w| let p = ($w | split row ":"); { surface: ($p.0 | into int), keys: ($p.1 | into int) } }),
            built: (do $of "built" | each {|w| $w | into int }),
        }
    } | sort-by frame
}

# The pool's knobs probed in one mode on the debug build, probe.nuon kept
export def main [mode: string, out: path, --seconds: int = 10] {
    let dbg = (target root $JAB | path join debug)
    let kernel = ($dbg | path join kernel jab.elf)
    let image = ($dbg | path join kit fierce fierce.jab)
    let disk = ($dbg | path join kit fierce still.romfs)
    let sends = (match $mode {
        "rotation" => [
            { at: 1300ms, bytes: (console workers 2 16) }
            { at: 1300ms, bytes: (packet-frame 7 500) }
            { at: 1500ms, bytes: (pool-frame --trace --cold --guarantee 1 --ring 4 --merge-us 1) }
            { at: 1500ms, bytes: (pose pose-frame $SPAWN_POSE) }
        ]
        "lifted" => [
            { at: 1500ms, bytes: (pool-frame --modes 1 --cold --guarantee 1) }
            { at: 1500ms, bytes: (pose pose-frame $SPAWN_POSE) }
        ]
        "ordinary" => [
            { at: 1500ms, bytes: (pool-frame --cold) }
            { at: 1500ms, bytes: (pose pose-frame $SPAWN_POSE) }
        ]
        "stale" => [
            { at: 1400ms, bytes: ([("L" | into binary), 0x[00 00 00], 0x[01], 0x[00], 0x[00], 0x[00], (0..<56 | each {|i| 0x[00] } | bytes collect)] | bytes collect) }
            { at: 1500ms, bytes: (pool-frame --modes 5 --cold --slots 64) }
            { at: 1500ms, bytes: (pose pose-frame $SPAWN_POSE) }
        ]
    })
    let run = (launch --kernel $kernel --image $image --out $out --set "DEBUG" --sound --api --disk $disk --serial "fps" --send $sends --capture 3000ms --seconds $seconds)
    let reference = ($dbg | path join kit fierce spawn_held screen.ppm)
    let differ = (if $mode == "stale" and ($run.screen != "") {
        let a = (open --raw $run.screen | into binary)
        let b = (open --raw $reference | into binary)
        let rows = (0..<1080 | where {|y| ($a | bytes at (17 + $y * 5760)..<(17 + ($y + 1) * 5760)) != ($b | bytes at (17 + $y * 5760)..<(17 + ($y + 1) * 5760)) })
        $rows | length
    } else { -1 })
    print $"probe ($mode): rows differing from the held capture ($differ)"
    let m = (gauge measure $run.api [{ name: "probe", places: [], pad: [] }])
    let s = (gauge stream $run.api)
    let rows = ($m.rows | select -o frame entry admitted dropped filtered batch_source batch_admitted merged unprocessed evicted tiles_built missed_blocks hit_blocks straddling_blocks building slots_used guarantee ring merge_us config_flags)
    let trace = (pool-trace $run.serial)
    {
        status: $run.status, schema: $m.schema, complete: $m.complete, valid: $m.valid, problems: $m.problems, invalid: $m.invalid,
        configs: $s.configs, rows: $rows, trace: $trace,
        faults: ($run.serial | lines | where {|l| ($l starts-with "jab: ") or ($l starts-with "fps: tile pool changed") }),
    } | to nuon | save -f ($out | path join "probe.nuon")
    print $"probe ($mode): status ($run.status), schema ($m.schema), complete ($m.complete), valid ($m.valid), rows ($rows | length), trace ($trace | length), problems ($m.problems | str join '; '), invalid ($m.invalid | str join '; ')"
}
