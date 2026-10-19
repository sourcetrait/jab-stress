# walk's own CADENCE_TEST launches (WalkCadence): the measurement build
# made its own fixture, each run read by the reader's guest-only path
# with its test's admission. Each build is made in the Jab checkout and
# copied out with its flags, its romfs, its demand record, its home, and
# its kernel before the next, since every build of a symbol set lands in
# its tree's one output; the kernels, which read none of the symbols, are
# held to load the same bytes, their ELFs differing by the symbols their
# tables carry, and each run boots its own build's. walk's wrapper,
# example/walk/test/cadence.nu, runs each loop order with TIMING on and
# off on 1KA1, the event room's close, and a replay of the await order's
# TIMING run with frame 331's clamp among its frames; the bounded waits'
# four exits go through jab launch with frames of their own. A case's
# failure is raised with its name. Alone on the box, about two minutes.
use ../../../jab/sdk/nu/jab.nu
use ../../../jab/nu/mod/target
use cadence.nu

const HZ = 10000000
const PERIOD = 166666
const DT_MAX = 1000000
const QUIET = 60
const STALL_FIRST = 240
const STALL_LAST = 299
const STALL_TICKS = 250000
const CLAMP_NEXT = 331
const REPLAY_WAIT_S = 10
const EVENT_ROOM_PAST = 4
const SPEC = "1ka1"
const KEPT = [walk.jab flags walk.romfs demand.nuon home]
const FOUR = [await_off await_on prepare_off prepare_on]
const CASES = [await_off await_on prepare_off prepare_on event_room replay no_nonce nonce_cut no_replay replay_cut]
const VARIANTS = [
    { name: "await_off", set: "cadence,cadence_test" }
    { name: "await_on", set: "cadence,cadence_test,timing" }
    { name: "prepare_off", set: "cadence,cadence_test,prepare" }
    { name: "prepare_on", set: "cadence,cadence_test,prepare,timing" }
    { name: "event_room", set: "cadence,cadence_test,event_room,timing" }
    { name: "replay", set: "cadence,cadence_test,replay,timing" }
]
# the exits and the frames each sends (exit-bytes): none, a nonce cut to
# its first 8 bytes, a nonce alone before a replay build's stream, and a
# nonce before a replay header cut at 32 of its 64 bytes
const EXITS = [
    { name: "no_nonce", build: "await_off", frame: "none", status: 6, line: "walk: no nonce frame came within the wait" }
    { name: "nonce_cut", build: "await_off", frame: "nonce_cut", status: 6, line: "walk: no nonce frame came within the wait" }
    { name: "no_replay", build: "replay", frame: "nonce", status: 5, line: "walk: no replay stream came within the wait" }
    { name: "replay_cut", build: "replay", frame: "replay_cut", status: 5, line: "walk: no replay stream came within the wait" }
]

def main [
    jab_dir: path                  # the Jab checkout the builds are made in
    scratch: path                  # a directory the call makes, its builds and runs under it
    --only: string = ""            # the cases to run, comma separated, every one unless given; a replay brings its reference, an exit a run to time it by
] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    let only = (if $only == "" { [] } else { $only | split row "," | each {|c| $c | str trim } })
    let unknown = ($only | where {|c| $c not-in $CASES })
    if not ($unknown | is-empty) { fail "--only" $"no such case: ($unknown | str join ', '); the cases are ($CASES | str join ', ')" }
    mkdir $scratch
    let ws = ($jab_dir | path expand)
    let wrapper = ($ws | path join "example" "walk" "test" "cadence.nu")
    let builds = ($scratch | path join "builds")
    let asked = (if ($only | is-empty) { $CASES } else { $only })
    let exits_asked = ($EXITS | where {|e| $e.name in $asked })
    let timed_by = (if (not ($exits_asked | is-empty)) and ($FOUR | all {|c| $c not-in $asked }) { ["await_off"] } else { [] })
    let runs_asked = ($FOUR | where {|c| $c in $asked or $c in $timed_by or ($c == "await_on" and "replay" in $asked) })
    let builds_asked = ($VARIANTS | where {|v| $v.name in $runs_asked or ($v.name in ["event_room" "replay"] and $v.name in $asked) or ($v.name in ($exits_asked | each {|e| $e.build })) })
    let made = ($builds_asked | each {|v| build-variant $ws $v.set ($builds | path join $v.name) | merge { name: $v.name } })
    if ($made | get kernel_loaded_sha256 | uniq | length) != 1 { fail "the kernel" $"the builds' kernels load different bytes: ($made | select name kernel_loaded_sha256 | to nuon)" }
    let image = {|name: string| $builds | path join $name "walk.jab" }
    let kernel_of = {|name: string| $builds | path join $name "jab.elf" }
    let runs = ($scratch | path join "runs")

    # each loop order with TIMING on and off
    let four = ($runs_asked | each {|name|
        let r = (wrapped $wrapper (do $image $name) (do $kernel_of $name) ($runs | path join $name) $name)
        four-holds $name $r
        print $"walk launches: ($name): ($r.stream.frames | length) frames, the stall's median interval (stall-median $r.stream.frames) ms"
        { name: $name, run: $r }
    })

    # the event room: the first frame past four events closes the window, nothing omitted
    if "event_room" in $asked {
        let room = (wrapped $wrapper (do $image "event_room") (do $kernel_of "event_room") ($runs | path join "event_room") "event_room")
        room-holds $room
        print $"walk launches: event_room: closed at frame ($room.stream.frames | last | get frame) with ($room.stream.header.events) events, ($room.stream.end.omitted) omitted"
    }

    # a replay of the await order's TIMING run, its workload frame for frame
    if "replay" in $asked {
        let reference = ($four | where name == "await_on" | first | get run)
        let stream_file = ($scratch | path join "await_on.wrpl")
        cadence replay-stream $reference.bytes | save --raw $stream_file
        let replayed = (wrapped $wrapper (do $image "replay") (do $kernel_of "replay") ($runs | path join "replay") "replay" --replay $stream_file)
        replay-holds $replayed $reference
        print $"walk launches: replay: ($replayed.stream.frames | length) frames, the reference's workload and dt frame for frame"
    }

    # the bounded waits' exits, inside the wait plus a second past reaching it
    let reach = (if ($four | is-empty) { 0 } else { (($four | each {|c| $c.run.stream.header.opened } | math max) / $HZ) + 0.5 })
    for e in $exits_asked {
        let bytes = (exit-bytes $e.frame)
        let sends = (if ($bytes | bytes length) == 0 { [] } else { [{ at: 200ms, bytes: $bytes }] })
        let dir = ($builds | path join $e.build)
        let r = (jab launch --kernel ($dir | path join "jab.elf") --image ($dir | path join "walk.jab") --out ($runs | path join $e.name) --disk ($dir | path join "walk.romfs") --serial "walk" --api --send $sends --seconds 60)
        if $r.status != $e.status { fail $e.name $"status ($r.status), not ($e.status): ($r.serial | str trim)" }
        if ($r.serial | str trim) != $e.line { fail $e.name $"the UART says ($r.serial | str trim | to nuon)" }
        if $r.wall_seconds < $REPLAY_WAIT_S or $r.wall_seconds > ($REPLAY_WAIT_S + $reach + 1) { fail $e.name $"($r.wall_seconds) s of wall time, the wait ($REPLAY_WAIT_S) s past reaching it within ($reach) s" }
        print $"walk launches: ($e.name): status ($r.status) after ($r.wall_seconds | math round -p 2) s"
    }
    print "walk launches: ok"
}

def fail [name: string, why: string] {
    error make { msg: $"walk launches: ($name): ($why)" }
}

# An exit case's frame: none, the nonce's frame cut to its first 8 bytes,
# the frame whole, or the frame whole before a replay header's first 32
# bytes, its magic, schema 1, and 16 frames then zeros.
def exit-bytes [frame: string]: nothing -> binary {
    let nonce = (jab nonce-frame 77)
    let word = {|v: int| $v | into binary --endian little | bytes at 0..<4 }
    let cut = ([(do $word 0x4c505257) (do $word 1) (do $word 16)] | bytes collect) ++ (0..<20 | each { 0x[00] } | bytes collect)
    match $frame {
        "none" => 0x[]
        "nonce_cut" => ($nonce | bytes at 0..<8)
        "nonce" => $nonce
        "replay_cut" => ($nonce ++ $cut)
        _ => { fail $frame "no such frame" }
    }
}

# A variant built in the checkout and its outputs copied out: the image,
# its flags, its romfs, its demand record, its home, and the kernel built
# with its symbols, whose loaded bytes (objcopy's flat image, with the
# tool prefix the kernel's flags stamp ends with) are hashed; the ELF
# differs build to build by the symbols its table carries.
def build-variant [ws: path, set: string, dest: path]: nothing -> record<image: string, kernel: string, kernel_loaded_sha256: string> {
    let r = (do { cd $ws; ^just build example/walk --set $set } | complete)
    if $r.exit_code != 0 { fail $"the build of ($set)" ($r.stdout + $r.stderr | str trim) }
    let target = (target root $ws)
    let out = ($target | path join "release" "example" "walk")
    mkdir $dest
    for f in $KEPT { cp ($out | path join $f) ($dest | path join $f) }
    let flags = (open --raw ($dest | path join "flags") | decode | lines | get 0)
    let wanted = ($set | split row "," | each {|s| $"--defsym ($s | str uppercase)=1" })
    if not ($wanted | all {|w| $flags | str contains $w }) { fail $"the build of ($set)" $"its flags ($flags)" }
    let kernel_dir = ($target | path join "release" "kernel")
    let kernel = ($dest | path join "jab.elf")
    cp ($kernel_dir | path join "jab.elf") $kernel
    let prefix = (open --raw ($kernel_dir | path join "flags") | decode | lines | get 0 | split row " " | last)
    let loaded = ($dest | path join "jab.bin")
    let o = (^$"($prefix)objcopy" -O binary $kernel $loaded | complete)
    if $o.exit_code != 0 { fail $"the build of ($set)" $"objcopy of its kernel: ($o.stderr | str trim)" }
    { image: ($dest | path join "walk.jab"), kernel: $kernel, kernel_loaded_sha256: (open --raw $loaded | hash sha256) }
}

# One run through walk's wrapper, its records read whole: the wrapper's
# exit, its identity, the API's bytes, the guest-only reading, and the
# stream as the reader reads it.
def wrapped [wrapper: path, image: path, kernel: path, out: path, label: string, --replay: path]: nothing -> record {
    let extra = (if $replay == null { [] } else { [--replay $replay] })
    let r = (^nu $wrapper $image $kernel --spec $SPEC --out $out --label $label ...$extra | complete)
    if $r.exit_code != 0 { fail $label $"the wrapper exited ($r.exit_code): ($r.stdout + $r.stderr | str trim)" }
    let identity = (open --raw ($out | path join "identity.nuon") | decode | from nuon)
    let api = ($out | path join "api.out")
    let bytes = (if ($api | path exists) { open --raw $api | into binary } else { 0x[] })
    let reading = (cadence guest-reading $bytes $identity --test)
    if not $reading.valid { fail $label $"the reading refused it: ($reading.faults | to nuon)" }
    { identity: $identity, bytes: $bytes, reading: $reading, stream: (cadence stream-of $bytes --test) }
}

# Each frame's start to the next's, for the frames first to last.
def intervals [frames: list<record>, first: int, last: int]: nothing -> list<int> {
    $first..$last | each {|i| ($frames | get ($i + 1) | get start) - ($frames | get $i | get start) }
}

def stall-median [frames: list<record>]: nothing -> float {
    ((intervals $frames $STALL_FIRST $STALL_LAST) | math median) / 10000.0
}

# What the four launches hold beside their readings' validity, which
# holds the stream, the receipt stage, the binding, and the arm's stamps.
def four-holds [name: string, r: record] {
    let frames = $r.stream.frames
    let fl = (cadence flags-of $r.stream.header.flags)
    let ords = ($frames | where {|f| $f.issued == 1 and $f.status == 0 } | get ordinal)
    if ($ords | first) != 2 or ($ords | window 2 | any {|p| $p.1 != $p.0 + 1 }) { fail $name "the presents' ordinals are not consecutive from 2" }
    if $r.stream.header.nonce != $r.identity.capture_nonce { fail $name "the header's nonce is not the one sent" }
    let empty = ($frames | first $QUIET)
    if ($empty | any {|f| $f.waited != 1 or $f.issued != 0 or $f.ordinal != 1 or $f.s != 0 or $f.t != 0 }) { fail $name "an empty frame flipped, skipped its wait, or carried a receipt" }
    let quiet = (intervals $frames 0 ($QUIET - 2))
    if ($quiet | math min) <= ($PERIOD / 2) { fail $name $"two empty frames back to back, ($quiet | math min) ticks apart" }
    let quiet_median = ($quiet | math median)
    if (($quiet_median - $PERIOD) | math abs) > 5000 { fail $name $"the empty frames' median interval ($quiet_median) ticks, not a period within 0.5 ms" }
    let stall = (intervals $frames $STALL_FIRST $STALL_LAST)
    if ($stall | any {|t| $t < $STALL_TICKS }) { fail $name $"a stall interval under 25 ms: ($stall | math min) ticks" }
    let stall_median = ($stall | math median)
    if $fl.prepare and $stall_median >= (2 * $PERIOD) { fail $name $"the stall's median interval ($stall_median) ticks, two periods or more in the prepare order" }
    if (not $fl.prepare) and $stall_median <= (2 * $PERIOD) { fail $name $"the stall's median interval ($stall_median) ticks, two periods or fewer in the await order" }
    let clamped = ($frames | get $CLAMP_NEXT)
    if $clamped.raw <= $DT_MAX or $clamped.dt != $DT_MAX { fail $name $"frame ($CLAMP_NEXT)'s raw ($clamped.raw) and dt ($clamped.dt), not clamped" }
    if $fl.timing {
        let span = {|first: int, last: int| $frames | skip $first | first ($last - $first + 1) }
        let work = (do $span $STALL_FIRST $STALL_LAST | each {|f| $f.work_end - $f.start })
        if ($work | any {|w| $w < $STALL_TICKS }) { fail $name $"a stall frame's work under 25 ms: ($work | math min) ticks" }
        let waits = {|first: int, last: int| do $span $first $last | each {|f| $f.wait_end - $f.wait_start } | math median }
        if $fl.prepare {
            let stalled = (do $waits $STALL_FIRST $STALL_LAST)
            let default = (do $waits 100 ($STALL_FIRST - 1))
            if $stalled >= 10000 { fail $name $"the stall's median wait ($stalled) ticks, 1 ms or more, where the tick has long passed" }
            if $default <= 10000 { fail $name $"the default frames' median wait ($default) ticks, 1 ms or less, where a real wait comes" }
        } else {
            let stalled = (do $waits ($STALL_FIRST + 1) $STALL_LAST)
            if $stalled <= ($PERIOD / 2) { fail $name $"the stall's median wait ($stalled) ticks after its first frame, half a period or less" }
        }
    } else {
        if $r.reading.reading.phases != { work: null, wait: null, call: null } { fail $name $"the TIMING-off phases read ($r.reading.reading.phases | to nuon)" }
    }
}

# The event room's close: ended by it, nothing omitted, at the first
# frame whose events passed four, the buffer's room past the headroom.
def room-holds [r: record] {
    let h = $r.stream.header
    if $h.ended != 3 { fail "event_room" $"ended by ($h.ended), not the event room" }
    if $r.stream.end.omitted != 0 { fail "event_room" $"($r.stream.end.omitted) events omitted" }
    mut total = 0
    mut totals = []
    for f in $r.stream.frames {
        $total += ($f.enters + $f.leaves)
        $totals = ($totals | append $total)
    }
    let n = ($totals | length)
    if ($totals | last) <= $EVENT_ROOM_PAST { fail "event_room" $"the window closed at ($totals | last) events" }
    if $n > 1 and ($totals | get ($n - 2)) > $EVENT_ROOM_PAST { fail "event_room" "the window ran past the first frame whose events passed four" }
    if $h.events != ($totals | last) { fail "event_room" $"the header counts ($h.events) events, the frames ($totals | last)" }
}

# The replay: ended by its last frame, its frames the reference's count,
# its workload the reference's frame for frame, its dt the reference's,
# frame 331's clamp among them.
def replay-holds [r: record, reference: record] {
    if $r.stream.header.ended != 4 { fail "replay" $"ended by ($r.stream.header.ended), not the replay's last frame" }
    let frames = $r.stream.frames
    let ref = $reference.stream.frames
    let faults = (cadence replay-faults $frames $ref)
    if not ($faults | is-empty) { fail "replay" ($faults | to nuon) }
    if ($frames | get dt) != ($ref | get dt) { fail "replay" "its dt values are not the reference's" }
    if ($frames | get $CLAMP_NEXT | get dt) != $DT_MAX { fail "replay" $"frame ($CLAMP_NEXT)'s dt is not the reference's clamp" }
}
