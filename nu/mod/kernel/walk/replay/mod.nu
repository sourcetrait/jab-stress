use (path self ../stream) [FRAMES_MAX fault faults-of joined le stream-of]

# A replay stream's magic, WRPL little-endian
const REPLAY_MAGIC = 0x4c505257

# A replay stream's header bytes
const REPLAY_HEADER = 64

# A replay stream's dt values, held to its header
def replay-dts [bytes: binary]: nothing -> record<seed: int, dts: list<int>, faults: list<any>> {
    let size = ($bytes | bytes length)
    if $size < $REPLAY_HEADER { return { seed: 0, dts: [], faults: [(fault "the replay's stream" 1 [$"($size) bytes, its header ($REPLAY_HEADER)"])] } }
    let n = (le $bytes 8 4)
    let wrong = ([
        (if (le $bytes 0 4) != $REPLAY_MAGIC { "its magic" })
        (if (le $bytes 4 4) != 1 { $"schema (le $bytes 4 4)" })
        (if $n < 1 or $n > $FRAMES_MAX { $"($n) frames" })
        (if $size != ($REPLAY_HEADER + $n * 4) { $"($size) bytes for ($n) frames" })
    ] | compact)
    if not ($wrong | is-empty) { return { seed: 0, dts: [], faults: [(fault "the replay's stream" ($wrong | length) $wrong)] } }
    { seed: (le $bytes 16 8), dts: (0..<$n | each {|i| le $bytes ($REPLAY_HEADER + $i * 4) 4 }), faults: [] }
}

# A replay run held to the stream its identity binds: SHA-256, seed, frames, dt
export def replay-bound-faults [stream: record, identity: record, replay: any]: nothing -> list<any> {
    let bound = ($identity | get -o replay)
    if $bound == null { return [(fault "the replay" 1 ["a REPLAY build's identity names no replay stream"])] }
    let file = (if $replay != null { $replay | path expand } else { $bound.file })
    if not ($file | path exists) { return [(fault "the replay" 1 [$"its stream is not at ($file)"])] }
    let bytes = (open --raw $file | into binary)
    let sha = ($bytes | hash sha256)
    if $sha != $bound.sha256 { return [(fault "the replay" 1 [$"its stream's SHA-256 ($sha), the identity's ($bound.sha256)"])] }
    let read = (replay-dts $bytes)
    if not ($read.faults | is-empty) { return $read.faults }
    let frames = $stream.frames
    let differ = ($frames | zip $read.dts | where {|p| $p.0.dt != $p.1 })
    joined [
        (if $read.seed != $stream.header.seed { [(fault "the replay's seed" 1 [$"the header's ($stream.header.seed), its stream's ($read.seed)"])] } else { [] })
        (if ($frames | length) != ($read.dts | length) { [(fault "the replay's frames" 1 [$"($frames | length) frames, its stream's ($read.dts | length)"])] } else { [] })
        (faults-of "the replay's dt" $differ {|p| $"frame ($p.0.frame): dt ($p.0.dt), its stream's ($p.1)" })
    ]
}

# A replay stream from a run's own records, its dt values the run's
export def replay-stream [bytes: binary]: nothing -> binary {
    let stream = (stream-of $bytes --test)
    if not $stream.complete or not ($stream.faults | is-empty) { error make { msg: $"the reference does not read whole: ($stream.faults | get rule | str join ', ')" } }
    let n = ($stream.frames | length)
    let word = {|v: int, size: int| $v | into binary --endian little | bytes at 0..<$size }
    let head = ([
        (do $word $REPLAY_MAGIC 4) (do $word 1 4) (do $word $n 4) (do $word 0 4)
        (do $word $stream.header.seed 8) (do $word 0 8) ($bytes | hash sha256 --binary)
    ] | bytes collect)
    $head ++ ($stream.frames | each {|f| do $word $f.dt 4 } | bytes collect)
}

# A replay run's workload held to its reference's frame for frame
export def replay-faults [replay: list<record>, reference: list<record>]: nothing -> list<any> {
    let fields = [walkers rects rect_area drawn enters leaves]
    if ($replay | length) != ($reference | length) { return [(fault "the replay's frames" 1 [$"($replay | length) frames, the reference's ($reference | length)"])] }
    let differ = ($replay | zip $reference | enumerate | where {|r| $fields | any {|k| ($r.item.0 | get $k) != ($r.item.1 | get $k) } })
    faults-of "the replay's workload" $differ {|r| $"frame ($r.index)" }
}
