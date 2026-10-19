use (path self ../../../../../jab/nu/mod/present)
use (path self ../../../../../jab/nu/mod/sdl)
use (path self ../../selection)

# The stream's header's bytes
const HEADER = 80

# A frame record's bytes
const FRAME = 80

# An event record's bytes
const EVENT = 8

# The end record's bytes
const END = 64

# The stream's schema the reader reads
const SCHEMA = 4

# The stream's magic, WCAD little-endian
const MAGIC = 0x44414357

# A frame's status where no flip was issued
const NO_STATUS = 255

# The kernel's tick, the clock's 10 MHz over the cap's 60
const PERIOD = 166666

# The clock's ticks a second, the one rate the reader reads
const HZ = 10000000

# A measurement's least window, 60 s in ticks
const SHORTEST = 600000000

# A measurement's window, 120 s in ticks
const WINDOW = 1200000000

# A CADENCE_TEST build's window, 10 s in ticks
const TEST_WINDOW = 100000000

# The most frames a window holds, walk's frame buffer
const FRAMES_MAX = 8192

# The most events a build buffers
const EVENTS_MAX = 4096

# The events a frame can add, held free before each frame
const EVENT_HEADROOM = 48

# The events an EVENT_ROOM build buffers past its headroom
const ROOM_PAST = 4

# walk's clamp on a frame's dt, a tenth of a second in ticks
const DT_MAX = 1000000

# The largest raw elapsed a frame stores, its u32 saturated
const RAW_MAX = 4294967295

# The header's flags hold no bit at or past this one
const FLAGS_PAST = 32

# The header's TIMING flag
const TIMING = 1

# The header's REPLAY flag
const REPLAY = 2

# The header's PREPARE flag
const PREPARE = 4

# The header's CADENCE_TEST flag
const TEST = 8

# The header's EVENT_ROOM flag
const EVENT_ROOM = 16

# Each header flag's build symbol
const SYMBOLS = { timing: "TIMING", replay: "REPLAY", prepare: "PREPARE", test: "CADENCE_TEST", event_room: "EVENT_ROOM" }

# The fields an identity names its build by
const BUILD_FIELDS = [cadence flags image kernel workload]

# What a historical reading, its identity naming no build, leaves unchecked
const HISTORICAL_UNCHECKED = [
    "the arm: the header's flags against the build's symbols"
    "the build: its image's and its kernel's SHA-256"
    "the window's field and the events' bound against the build's, held to the header's own flags alone"
]

# A replay stream's magic, WRPL little-endian
const REPLAY_MAGIC = 0x4c505257

# A replay stream's header bytes
const REPLAY_HEADER = 64

# A slow stretch's least host flip interval, 1.5 periods in microseconds
const STRETCH_US = 25000

# The least presented flips a slow stretch holds
const STRETCH_FLIPS = 5

# The guest's phases a stretch is located by
const PHASES = [work wait call]

# What can end a window, by the header's code
const ENDS = ["none" "the duration" "the frame buffer" "the event room" "the replay's last frame" "an offset's range"]

# What a guest-only reading cannot claim, stated with it
const LIMITS = [
    "rdtime is elapsed time: a host stall inside a phase reads as that phase"
    "the guest's records give intervals between its own clock's readings, and nothing of when the host showed a frame"
    "attribution is within a run, by a stretch's own frames against the run's steady medians, never by comparing runs"
]

# What a paired reading cannot claim, stated with it beside the pairing's own
const PAIRED_LIMITS = [
    "rdtime is elapsed time: a host stall inside a phase reads as that phase"
    "the pairing gives intervals and no absolute guest-to-SDL latency; its own limits are the pairing core's, given with it"
    "attribution is within a run, by a stretch's own frames against the run's steady medians, never by comparing runs"
    "a TIMING-off run pairs on its frame's bracket, never a call's, and locates no phase"
]

# A little-endian word of `size` bytes at `at`, the eight-byte one signed
def le [b: binary, at: int, size: int]: nothing -> int {
    let w = ($b | bytes at $at..<($at + $size))
    if $size == 8 { $w | into int --endian little --signed } else { $w | into int --endian little }
}

# A fault as the reading names it: rule, count, and examples
def fault [rule: string, held: int, examples: list<string>]: nothing -> record<rule: string, held: int, examples: list<string>> {
    { rule: $rule, held: $held, examples: ($examples | first 4) }
}

# The rows that break a rule as one fault, none when no row does
def faults-of [rule: string, rows: list<any>, example: closure]: nothing -> list<any> {
    if ($rows | is-empty) { [] } else { [(fault $rule ($rows | length) ($rows | each $example))] }
}

# Lists of faults joined in order
def joined [lists: list<any>]: nothing -> list<any> {
    $lists | reduce --fold [] {|x, acc| $acc ++ $x }
}

# The CRC-32 of the bytes, IEEE's, through coreutils' cksum
export def crc-of [bytes: binary]: nothing -> int {
    let r = ($bytes | ^cksum -a crc32b | complete)
    if $r.exit_code != 0 { error make { msg: $"cksum -a crc32b failed: ($r.stderr | str trim)" } }
    $r.stdout | split row " " | first | into int
}

# The stream's header record read from its bytes
export def header-of [b: binary]: nothing -> record {
    {
        kind: (le $b 0 1), ended: (le $b 1 1), anchors: (le $b 2 2), magic: (le $b 4 4),
        schema: (le $b 8 4), frames: (le $b 12 4), events: (le $b 16 4), rate: (le $b 20 4),
        seed: (le $b 24 8), window: (le $b 32 4), frame_size: (le $b 36 2), event_size: (le $b 38 2),
        flags: (le $b 40 4), trail: (le $b 44 2), size: (le $b 46 2), origin: (le $b 48 8),
        opened: (le $b 56 8), nonce: (le $b 64 8), zero: (le $b 72 8),
    }
}

# The end record read from its bytes
def end-of [b: binary]: nothing -> record {
    {
        kind: (le $b 0 1), zero_head: ($b | bytes at 1..<4), magic: (le $b 4 4), schema: (le $b 8 4),
        frames: (le $b 12 4), events: (le $b 16 4), crc: (le $b 20 4), omitted: (le $b 24 4),
        zero: ($b | bytes at 28..<64),
    }
}

# A frame record read from its bytes
def frame-of [b: binary]: nothing -> record {
    {
        kind: (le $b 0 1), issued: (le $b 1 1), status: (le $b 2 1), walkers: (le $b 3 1),
        frame: (le $b 4 4), start: (le $b 8 4), call_end: (le $b 12 4), wait_start: (le $b 16 4),
        wait_end: (le $b 20 4), work_end: (le $b 24 4), call_start: (le $b 28 4), raw: (le $b 32 4),
        dt: (le $b 36 4), rects: (le $b 40 2), enters: (le $b 42 1), leaves: (le $b 43 1),
        rect_area: (le $b 44 4), s: (le $b 48 8), t: (le $b 56 8), ordinal: (le $b 64 4),
        drawn: (le $b 68 4), waited: (le $b 72 1), pad: (le $b 73 3), schema: (le $b 76 4),
    }
}

# An event record read from its bytes
def event-of [b: binary]: nothing -> record {
    { kind: (le $b 0 1), lane: (le $b 1 1), side: (le $b 2 1), scale: (le $b 3 1), tint: (le $b 4 4) }
}

# The flags a header carries, by name
export def flags-of [flags: int]: nothing -> record<timing: bool, replay: bool, prepare: bool, test: bool, event_room: bool> {
    {
        timing: (($flags bit-and $TIMING) != 0), replay: (($flags bit-and $REPLAY) != 0),
        prepare: (($flags bit-and $PREPARE) != 0), test: (($flags bit-and $TEST) != 0),
        event_room: (($flags bit-and $EVENT_ROOM) != 0),
    }
}

# The window's field a build writes, by its flags
def window-of [fl: record]: nothing -> int {
    if $fl.replay { 0 } else if $fl.test { $TEST_WINDOW } else { $WINDOW }
}

# The events a build buffers, by its flags
def events-max [fl: record]: nothing -> int {
    if $fl.event_room { $EVENT_HEADROOM + $ROOM_PAST } else { $EVENTS_MAX }
}

# The stream read whole and held to its rules, every fault named
export def stream-of [bytes: binary, --test]: nothing -> record {
    let size = ($bytes | bytes length)
    let ended = {|f: record| { complete: false, faults: [$f], header: null, frames: [], events: [], end: null } }
    if $size < $HEADER { return (do $ended (fault "no header" 1 [$"the stream is ($size) bytes"])) }
    let h = (header-of ($bytes | bytes at 0..<$HEADER))
    let fl = (flags-of $h.flags)
    let wrong = ([
        (if $h.kind != 4 { $"kind ($h.kind)" })
        (if $h.magic != $MAGIC { $"magic 0x($h.magic | format number | get lowerhex | str substring 2..)" })
        (if $h.schema != $SCHEMA { $"schema ($h.schema)" })
        (if $h.size != $HEADER { $"a header of ($h.size) bytes" })
        (if $h.frame_size != $FRAME { $"frame records of ($h.frame_size) bytes" })
        (if $h.event_size != $EVENT { $"event records of ($h.event_size) bytes" })
        (if $h.zero != 0 { "bytes 72 to 79 not zero" })
        (if $h.rate != $HZ { $"a rate of ($h.rate) ticks a second, ($HZ) the one read" })
        (if $h.flags >= $FLAGS_PAST { $"flags ($h.flags), a bit past the five a header names" })
        (if $fl.event_room and not $fl.test { "EVENT_ROOM without CADENCE_TEST" })
        (if $h.frames > $FRAMES_MAX { $"($h.frames) frames, the buffer holding ($FRAMES_MAX)" })
        (if $h.events > (events-max $fl) { $"($h.events) events, its flags' build buffering (events-max $fl)" })
    ] | compact)
    if not ($wrong | is-empty) { return (do $ended (fault "the header" ($wrong | length) $wrong)) }
    let body = ($HEADER + $h.frames * $FRAME + $h.events * $EVENT)
    let whole = ($body + $END)
    if $size < $whole { return ((do $ended (fault "no end record" 1 [$"the stream ends at ($size) bytes, its records and end at ($whole)"])) | update header $h) }
    if $size > $whole { return ((do $ended (fault "the stream's length" 1 [$"($size - $whole) bytes past its end record"])) | update header $h) }
    let e = (end-of ($bytes | bytes at $body..<$whole))
    let end_wrong = ([
        (if $e.kind != 5 { $"kind ($e.kind)" })
        (if $e.magic != $MAGIC { "the magic" })
        (if $e.schema != $SCHEMA { $"schema ($e.schema)" })
        (if not ((zeroed $e.zero_head) and (zeroed $e.zero)) { "its padding not zero" })
    ] | compact)
    if not ($end_wrong | is-empty) { return ((do $ended (fault "the end record" ($end_wrong | length) $end_wrong)) | update header $h) }
    if $e.frames != $h.frames or $e.events != $h.events {
        return ((do $ended (fault "the end's counts" 1 [$"the end counts ($e.frames) frames and ($e.events) events, the header ($h.frames) and ($h.events)"])) | update header $h)
    }
    let crc = (crc-of ($bytes | bytes at 0..<$body))
    if $crc != $e.crc { return ((do $ended (fault "the CRC" 1 [$"the records' CRC-32 is ($crc), the end's ($e.crc)"])) | update header $h) }
    let frames = (0..<$h.frames | each {|i| frame-of ($bytes | bytes at ($HEADER + $i * $FRAME)..<($HEADER + ($i + 1) * $FRAME)) })
    let event_base = ($HEADER + $h.frames * $FRAME)
    let events = (0..<$h.events | each {|i| event-of ($bytes | bytes at ($event_base + $i * $EVENT)..<($event_base + ($i + 1) * $EVENT)) })
    let at = {|f: record| $"frame ($f.frame)" }
    let indexed = ($frames | enumerate)
    let last = ($frames | last)
    let window = (if $last == null { 0 } else { $last.call_end })
    let enters = ($frames | get -o enters | default [] | math sum)
    let leaves = ($frames | get -o leaves | default [] | math sum)
    let entered = ($events | where kind == 1 | length)
    let left = ($events | where kind == 2 | length)
    let ends = (if $fl.replay { [4] } else { [1 3] })
    let faults = (joined [
        (faults-of "the record" ($frames | where {|f| $f.kind != 1 or $f.schema != $SCHEMA or $f.pad != 0 or $f.issued not-in [0 1] or $f.status not-in [0 1 2 3 4 $NO_STATUS] }) $at)
        (faults-of "the numbering" ($indexed | where {|r| $r.item.frame != $r.index }) {|r| $"record ($r.index) numbered ($r.item.frame)" })
        (faults-of "the wait" ($frames | where {|f| $f.waited != 1 }) $at)
        (faults-of "the final status" ($frames | where {|f| $f.status in [2 3 4] }) {|f| $"frame ($f.frame) status ($f.status)" })
        (if $fl.timing { phase-faults $frames $fl.prepare } else { untimed-faults $frames })
        (elapsed-faults $frames $fl.replay)
        (faults-of "the events" ($events | where {|v| $v.kind not-in [1 2] or $v.lane >= 8 }) {|v| $"kind ($v.kind) lane ($v.lane)" })
        (if $e.omitted > 0 { [(fault "an event omitted" $e.omitted [$"($e.omitted) past the buffer"])] } else { [] })
        (if $e.omitted == 0 and ($enters != $entered or $leaves != $left) { [(fault "the events' counts" 1 [$"the frames count ($enters) enters and ($leaves) leaves, the events ($entered) and ($left)"])] } else { [] })
        (if $h.window != (window-of $fl) { [(fault "the window's field" 1 [$"($h.window) ticks, its flags' build writing (window-of $fl)"])] } else { [] })
        (if $h.ended not-in $ends { [(fault "the window's end" 1 [$"ended by ((if $h.ended < ($ENDS | length) { $ENDS | get $h.ended } else { $'end ($h.ended)' })), where a ((if $fl.replay { 'replay' } else { 'measurement' })) ends by ($ends | each {|x| $ENDS | get $x } | str join ' or ')"])] } else { [] })
        (end-faults $h $frames $fl)
        (if $h.nonce == 0 { [(fault "the nonce" 1 ["the header's capture nonce is 0"])] } else { [] })
        (if $fl.test and not $test { [(fault "a test build" 1 ["a CADENCE_TEST build, read by its own test alone"])] } else { [] })
        (if (not $fl.replay) and (not $fl.test) and $window < $SHORTEST { [(fault "a short window" 1 [$"($window / $HZ) s of window, 60 s the least"])] } else { [] })
        (if $h.frames == 0 { [(fault "no frame" 1 ["the window holds no frame"])] } else { [] })
    ])
    { complete: true, faults: $faults, header: $h, frames: $frames, events: $events, end: $e }
}

# Whether every byte is zero
def zeroed [b: binary]: nothing -> bool {
    ($b | bytes replace --all 0x[00] 0x[] | bytes length) == 0
}

# A TIMING build's frames out of their arm's phase order
def phase-faults [frames: list<record>, prepare: bool]: nothing -> list<any> {
    let order = (if $prepare { [start work_end wait_start wait_end call_start call_end] } else { [wait_start wait_end start work_end call_start call_end] })
    let broken = ($frames | enumerate | where {|r|
        let f = $r.item
        let stamps = ($order | each {|k| $f | get $k })
        let inside = ($stamps | window 2 | any {|p| $p.0 > $p.1 })
        $inside or (if $r.index > 0 { $f.start < ($frames | get ($r.index - 1) | get call_end) } else { false })
    })
    faults-of "the phase order" $broken {|r| $"frame ($r.item.frame)" }
}

# A build without TIMING: its four fields zero, its stamps in order
def untimed-faults [frames: list<record>]: nothing -> list<any> {
    let fields = ($frames | where {|f| $f.wait_start != 0 or $f.wait_end != 0 or $f.work_end != 0 or $f.call_start != 0 })
    let order = ($frames | enumerate | where {|r|
        let next = ($frames | get -o ($r.index + 1))
        $r.item.start > $r.item.call_end or ($next != null and $r.item.call_end > $next.start)
    })
    (faults-of "a TIMING field without TIMING" $fields {|f| $"frame ($f.frame)" }) ++ (faults-of "the stamps' order" $order {|r| $"frame ($r.item.frame)" })
}

# Each frame's raw elapsed its start less the one before, a measured dt its clamp
def elapsed-faults [frames: list<record>, replay: bool]: nothing -> list<any> {
    let raws = ($frames | enumerate | each {|r|
        let previous = (if $r.index == 0 { 0 } else { $frames | get ($r.index - 1) | get start })
        let wanted = ([($r.item.start - $previous) $RAW_MAX] | math min)
        if $r.item.raw != $wanted { { frame: $r.item.frame, raw: $r.item.raw, wanted: $wanted } }
    } | compact)
    let dts = (if $replay { [] } else { $frames | where {|f| $f.dt != ([$f.raw $DT_MAX] | math min) } })
    (faults-of "the raw elapsed" $raws {|x| $"frame ($x.frame): raw ($x.raw), its start less the one before ($x.wanted)" }) ++ (faults-of "the dt" $dts {|f| $"frame ($f.frame): dt ($f.dt) for raw ($f.raw), the lesser of it and ($DT_MAX) wanted" })
}

# The window's end held to where its build's end rules first fired
def end-faults [h: record, frames: list<record>, fl: record]: nothing -> list<any> {
    if ($frames | is-empty) { return [] }
    let room = ((events-max $fl) - $EVENT_HEADROOM)
    mut count = 0
    mut fired: any = null
    for r in ($frames | enumerate) {
        $count += ($r.item.enters + $r.item.leaves)
        let code = (if (not $fl.replay) and $r.item.call_end >= $h.window { 1 } else if ($r.index + 1) == $FRAMES_MAX { 2 } else if $count > $room { 3 } else { null })
        if $code != null {
            $fired = { index: $r.index, code: $code, events: $count }
            break
        }
    }
    let last = (($frames | length) - 1)
    if $fired != null and $fired.index < $last {
        return [(fault "the window's end" 1 [$"the window ran on past frame ($fired.index), where ($ENDS | get $fired.code) ended it"])]
    }
    if $fl.replay { return [] }
    if $fired == null {
        let l = ($frames | last)
        return [(fault "the window's end" 1 [$"no end came at its last frame, ($l.frame): its call's end ($l.call_end) under the window's ($h.window), its ($count) events within the room's ($room)"])]
    }
    if $fired.code != $h.ended {
        return [(fault "the window's end" 1 [$"ended by ((if $h.ended < ($ENDS | length) { $ENDS | get $h.ended } else { $'end ($h.ended)' })) where its last frame's rules give ($ENDS | get $fired.code)"])]
    }
    []
}

# The receipt stage's faults, before anything is read from a receipt
export def receipt-faults [frames: list<record>, origin: int, timing: bool]: nothing -> list<any> {
    let issue = ($frames | where {|f|
        if $f.issued == 0 { $f.status != $NO_STATUS or $f.s != 0 or $f.t != 0 } else if $f.status in [0 1] { $f.s == 0 or $f.t == 0 } else { $f.status == $NO_STATUS }
    })
    let presents = ($frames | enumerate | each {|r|
        let f = $r.item
        let before = (if $r.index == 0 { 1 } else { $frames | get ($r.index - 1) | get ordinal })
        { presented: ($f.issued == 1 and ($f.status == 0 or ($f.status == 3 and $f.ordinal == $before + 1))), ordinal: $f.ordinal }
    })
    let violations = (present ordinal-violations 1 $presents)
    let ordinals = ($violations | group-by rule | items {|rule, rows| fault $"the present sequence: ($rule)" ($rows | length) ($rows | each {|v| $"frame ($v.index) at ($v.ordinal), ($v.wanted) wanted" }) } | default [])
    let accepted = ($frames | where {|f| $f.issued == 1 and $f.status == 0 } | where {|f|
        let low = ($origin + (if $timing { $f.call_start } else { $f.start }))
        let high = ($origin + $f.call_end)
        $f.s < $f.t or $f.s < $low or $f.s > $high
    })
    (faults-of "the receipt's flip" $issue {|f| $"frame ($f.frame): issued ($f.issued), status ($f.status), s ($f.s), T ($f.t)" }) ++ ($ordinals | sort-by rule) ++ (faults-of "the acceptance" $accepted {|f| $"frame ($f.frame): s ($f.s), T ($f.t)" })
}

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

# A replay run held to the stream its identity binds: its SHA-256, seed, frames, and dt
def replay-bound-faults [stream: record, identity: record, replay: any]: nothing -> list<any> {
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

# The identity's build held to the header; one naming no build read as historical
def identity-stage [stream: record, identity: record, replay: any]: nothing -> record<historical: bool, faults: list<any>, unchecked: list<string>, build: any> {
    let fl = (flags-of $stream.header.flags)
    let present = ($BUILD_FIELDS | where {|k| ($identity | get -o $k) != null })
    if ($present | is-empty) {
        let unchecked = ($HISTORICAL_UNCHECKED ++ (if $fl.replay { ["the replay: its frames, seed, and dt against its stream"] } else { [] }))
        return { historical: true, faults: [], unchecked: $unchecked, build: null }
    }
    if ($present | length) < ($BUILD_FIELDS | length) {
        let missing = ($BUILD_FIELDS | where {|k| $k not-in $present })
        return { historical: false, faults: [(fault "the identity's build" 1 [$"it names ($present | str join ', ') and not ($missing | str join ', ')"])], unchecked: [], build: null }
    }
    let cadence = $identity.cadence
    let named = {
        timing: ("TIMING" in $cadence), replay: ("REPLAY" in $cadence), prepare: ("PREPARE" in $cadence),
        test: ("CADENCE_TEST" in $cadence), event_room: ($identity.flags | str contains "--defsym EVENT_ROOM=1"),
    }
    let said = {|on: bool| if $on { "sets" } else { "clears" } }
    let arm = ($named | columns | where {|k| ($named | get $k) != ($fl | get $k) } | each {|k| $"($SYMBOLS | get $k): the header (do $said ($fl | get $k)) it, the build (do $said ($named | get $k)) it" })
    let order = ($identity | get -o workload.order | default "")
    let image = ($identity | get -o image.sha256 | default "")
    let kernel = ($identity | get -o kernel.sha256 | default "")
    let faults = (joined [
        (if "CADENCE" not-in $cadence { [(fault "the build" 1 [$"its symbols ($cadence | str join ' ') hold no CADENCE"])] } else { [] })
        (faults-of "the arm against the build" $arm {|x| $x })
        (if ($order == "prepare") != $fl.prepare { [(fault "the loop order" 1 [$"the identity's workload ($order), the header's PREPARE ($fl.prepare)"])] } else { [] })
        (if $image == "" or $kernel == "" { [(fault "the build's files" 1 ["the identity names no image or kernel SHA-256"])] } else { [] })
        (if $fl.replay { replay-bound-faults $stream $identity $replay } else { [] })
    ])
    { historical: false, faults: $faults, unchecked: [], build: { workload: $identity.workload, cadence: $cadence, image: $image, kernel: $kernel } }
}

# The nearest-rank percentile of the values, null for none
def rank [values: list<number>, p: float]: nothing -> any {
    if ($values | is-empty) { return null }
    let sorted = ($values | sort)
    let i = ([((($p * ($sorted | length)) | math ceil) - 1) 0] | math max)
    $sorted | get $i
}

# Ticks in milliseconds, null kept
def ms [ticks: any]: nothing -> any {
    if $ticks == null { null } else { $ticks / 10000.0 }
}

# A distribution's median and 95th in milliseconds, from ticks
def spread [ticks: list<number>]: nothing -> record<median_ms: any, p95_ms: any, count: int> {
    let ms = ($ticks | each {|t| $t / 10000.0 })
    { median_ms: (rank $ms 0.5), p95_ms: (rank $ms 0.95), count: ($ms | length) }
}

# A distribution's median and 95th in milliseconds, from microseconds
def spread-us [us: list<number>]: nothing -> record<median_ms: any, p95_ms: any, count: int> {
    let ms = ($us | each {|t| $t / 1000.0 })
    { median_ms: (rank $ms 0.5), p95_ms: (rank $ms 0.95), count: ($ms | length) }
}

# The guest's side of a reading, on a stream that held
export def guest-side [stream: record, eps: int]: nothing -> record {
    let fl = (flags-of $stream.header.flags)
    let frames = $stream.frames
    let starts = ($frames | get start)
    let intervals = ($starts | window 2 | each {|p| $p.1 - $p.0 })
    let phases = (if $fl.timing {
        {
            work: (spread ($frames | each {|f| $f.work_end - $f.start })),
            wait: (spread ($frames | each {|f| $f.wait_end - $f.wait_start })),
            call: (spread ($frames | where issued == 1 | each {|f| $f.call_end - $f.call_start })),
        }
    } else { { work: null, wait: null, call: null } })
    let accepted = ($frames | where {|f| $f.issued == 1 and $f.status == 0 } | get s)
    let presented = ($accepted | window 2 | each {|p| $p.1 - $p.0 })
    let k = (present k-violations $accepted $PERIOD $eps)
    let window_s = (($frames | last | get call_end) / $HZ)
    {
        frames: ($frames | length),
        window_s: $window_s,
        ended_by: ($ENDS | get $stream.header.ended),
        flags: $fl,
        frame_interval: (spread $intervals),
        presented_interval: (spread $presented),
        phases: $phases,
        presents: ($accepted | length),
        k: { eps: $eps, period: $PERIOD, violations: ($k | length), first: ($k | first 8) },
        workload: {
            drawn: { median: (rank ($frames | get drawn) 0.5), p95: (rank ($frames | get drawn) 0.95) },
            rect_area: { median: (rank ($frames | get rect_area) 0.5), p95: (rank ($frames | get rect_area) 0.95) },
            enters_per_s: (if $window_s > 0 { ($frames | get enters | math sum) / $window_s } else { null }),
        },
    }
}

# A stream read on the one path both readings take: rules, receipts, binding, build
def guest-of [bytes: binary, identity: record, eps: int, test: bool, replay: any]: nothing -> record<result: record, stream: record> {
    let stream = (stream-of $bytes --test=$test)
    let base = { reader: "walk cadence", mode: "guest", guest_only: true, limits: $LIMITS }
    if not $stream.complete {
        return { result: ($base | merge { complete: false, valid: false, faults: $stream.faults, nonce: null, historical: null, deciding: false, build: null, unchecked: [], reading: null }), stream: $stream }
    }
    let receipts = (if ($stream.frames | is-empty) { [] } else { receipt-faults $stream.frames $stream.header.origin (flags-of $stream.header.flags).timing })
    let wanted = ($identity | get -o capture_nonce)
    let binding = (if $wanted == null or $wanted == 0 or $wanted != $stream.header.nonce {
        [(fault "the binding" 1 [$"the header's nonce ($stream.header.nonce), the identity's ($wanted | to nuon)"])]
    } else { [] })
    let built = (identity-stage $stream $identity $replay)
    let faults = ($stream.faults ++ $receipts ++ $binding ++ $built.faults)
    let valid = ($faults | is-empty)
    let result = ($base | merge {
        complete: true, valid: $valid, faults: $faults, nonce: $stream.header.nonce,
        historical: $built.historical, deciding: ($valid and not $built.historical), build: $built.build, unchecked: $built.unchecked,
        reading: (if $valid { guest-side $stream $eps } else { null }),
    })
    { result: $result, stream: $stream }
}

# A guest-only reading: the stream, the receipts, the binding, the build, the guest
export def guest-reading [bytes: binary, identity: record, --eps: int = 10000, --test, --replay: path]: nothing -> record {
    (guest-of $bytes $identity $eps $test $replay).result
}

# Each presented flip's guest figures beside what the host's renders chose
def flip-rows [frames: list<record>, presented: list<record>, chosen: list<any>, timing: bool]: nothing -> list<any> {
    if ($presented | length) != ($chosen | length) { error make { msg: $"the selection holds ($chosen | length) pairs for ($presented | length) presents" } }
    $presented | zip $chosen | enumerate | each {|e|
        let f = $e.item.0
        let s = $e.item.1
        if $s.ordinal != $f.ordinal { error make { msg: $"the selection's pair ($e.index) is ordinal ($s.ordinal), its present's ($f.ordinal)" } }
        let before = (if $e.index == 0 { null } else { $presented | get ($e.index - 1) })
        {
            frame: $f.frame, ordinal: $f.ordinal, start: $f.start,
            frame_interval: (if $f.frame == 0 { null } else { $f.start - ($frames | get ($f.frame - 1) | get start) }),
            presented_interval: (if $before == null { null } else { $f.s - $before.s }),
            work: (if $timing { $f.work_end - $f.start } else { null }),
            wait: (if $timing { $f.wait_end - $f.wait_start } else { null }),
            call: (if $timing { $f.call_end - $f.call_start } else { null }),
            upload_interval_us: $s.upload_interval_us, age_us: $s.age_us, shown_interval_us: $s.shown_interval_us,
            renders: $s.renders, repeats: $s.repeats, shown: $s.shown, superseded: $s.superseded, unshown: $s.unshown,
        }
    }
}

# The presented flips' host side: what the renders chose, the intervals, the age
def flips-summary [rows: list<any>, renders: int]: nothing -> record {
    let n = ($rows | length)
    let shown = ($rows | where shown | length)
    {
        presents: $n, renders: $renders, shown: $shown,
        superseded: ($rows | where superseded | length),
        repeated: (if $n == 0 { 0 } else { $rows | get repeats | math sum }),
        unshown_at_end: ($rows | where unshown | length),
        share_shown: (if $n == 0 { null } else { $shown / $n }),
        host_interval: (spread-us ($rows | get upload_interval_us | compact)),
        presented_interval: (spread ($rows | get presented_interval | compact)),
        age: (spread-us ($rows | get age_us | compact)),
        shown_interval: (spread-us ($rows | get shown_interval_us | compact)),
    }
}

# A stretch's figure for one measure against the run's steady flips
def against-steady [name: string, stretch: list<any>, steady: list<any>]: nothing -> record {
    let mine = ($stretch | get $name | compact)
    let base = ($steady | get $name | compact)
    let median = (rank $mine 0.5)
    let p95 = (rank $base 0.95)
    {
        name: $name, median_ms: (ms $median), steady_median_ms: (ms (rank $base 0.5)), steady_p95_ms: (ms $p95),
        risen: ($median != null and $p95 != null and $median > $p95),
    }
}

# The slow stretches, each set against the run's steady flips and located
def stretches-of [rows: list<any>, timing: bool]: nothing -> list<any> {
    mut runs = []
    mut current = []
    for r in ($rows | enumerate) {
        let slow = ($r.item.upload_interval_us != null and $r.item.upload_interval_us >= $STRETCH_US)
        if $slow {
            $current = ($current | append $r.index)
        } else {
            if ($current | length) >= $STRETCH_FLIPS { $runs = ($runs | append [$current]) }
            $current = []
        }
    }
    if ($current | length) >= $STRETCH_FLIPS { $runs = ($runs | append [$current]) }
    let inside = ($runs | reduce --fold [] {|x, acc| $acc ++ $x })
    let steady = ($rows | enumerate | where {|r| $r.index not-in $inside } | get item)
    $runs | each {|run|
        let mine = ($run | each {|i| $rows | get $i })
        let phases = (if $timing { $PHASES | each {|k| against-steady $k $mine $steady } } else { null })
        let risen = (if $timing { $phases | where risen | get name } else { [] })
        {
            first: { frame: ($mine | first | get frame), ordinal: ($mine | first | get ordinal) },
            last: { frame: ($mine | last | get frame), ordinal: ($mine | last | get ordinal) },
            flips: ($mine | length),
            at_s: (($mine | first | get start) / $HZ),
            host_interval: (spread-us ($mine | get upload_interval_us | compact)),
            presented_interval: (spread ($mine | get presented_interval | compact)),
            frame_interval: (against-steady frame_interval $mine $steady),
            phases: $phases,
            located: (if not $timing { null } else if ($risen | is-empty) { ["delivery past the guest"] } else { $risen | each {|p| { work: "the work", wait: "the wait", call: "the flip call" } | get $p } }),
        }
    }
}

# A probed run read paired: its bundle, its stream, the pairing, the renders, the stretches
export def paired-reading [probe: path, --eps: int = 10000, --replay: path]: nothing -> record {
    let dir = ($probe | path expand)
    let bundle = ($dir | path join "bundle")
    let identity = (open --raw ($bundle | path join "identity.nuon") | into binary | decode | from nuon)
    let bytes = (open --raw ($bundle | path join "api.out") | into binary)
    let g = (guest-of $bytes $identity $eps false $replay)
    let base = ($g.result | merge { mode: "paired", guest_only: false, limits: $PAIRED_LIMITS, stage: null, capture: null, pairing: null, flips: null, stretches: null })
    if not $g.result.valid { return ($base | merge { stage: "stream" }) }
    let checked = (try { sdl bundle-check $bundle --guest {|api| header-nonce (open --raw $api | into binary) } } catch {|e| { refusal: $e.msg } })
    if ($checked | get -o refusal) != null {
        return ($base | merge { stage: "capture", valid: false, deciding: false, faults: ($g.result.faults ++ [(fault "the capture" 1 [$checked.refusal])]) })
    }
    let capture = ($checked | reject events)
    let timing = (flags-of $g.stream.header.flags).timing
    let origin = $g.stream.header.origin
    let frames = $g.stream.frames
    let presented = ($frames | where {|f| $f.issued == 1 and $f.status == 0 })
    let flips = ($presented | each {|f| { status: 0, ordinal: $f.ordinal, lo: ($origin + (if $timing { $f.call_start } else { $f.start })), hi: ($origin + $f.call_end) } })
    let pair = (sdl pair $checked.events $flips)
    let pairing = {
        verdict: $pair.verdict, refusals: $pair.refusals, bound: (if $timing { "recorded" } else { "frame" }),
        bracket: $pair.bracket, shifts: $pair.shifts, window: $pair.window, fit: $pair.fit,
        stalls: (if $timing { { calls: $pair.stalls, frame: [] } } else { { calls: [], frame: $pair.stalls } }),
        limits: $pair.limits,
    }
    if not $pair.ok {
        let refused = (fault "the pairing" ($pair.refusals | length) ($pair.refusals | each {|r| $"($r.refusal): ($r.count)" }))
        return ($base | merge { stage: "pairing", valid: false, deciding: false, capture: $capture, pairing: $pairing, faults: ($g.result.faults ++ [$refused]) })
    }
    let chosen = (selection $checked.events $pair.pairs)
    let rows = (flip-rows $frames $presented $chosen.frames $timing)
    $base | merge { capture: $capture, pairing: $pairing, flips: (flips-summary $rows $chosen.renders), stretches: (stretches-of $rows $timing) }
}

# The header's capture nonce from an export's bytes, null if too short
export def header-nonce [bytes: binary]: nothing -> any {
    if ($bytes | bytes length) < $HEADER { return null }
    (header-of ($bytes | bytes at 0..<$HEADER)).nonce
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

# A reading's record saved as NUON
def write [record: record, out: path]: nothing -> nothing {
    $record | to nuon --indent 1 | save --raw -f $out
}

# A reading's record printed for reading
def show [record: record]: nothing -> nothing {
    let state = (if $record.valid { "valid" } else if $record.complete { "invalid" } else { "incomplete" })
    let standing = (if $record.historical == true { ", historical, no deciding arm" } else if $record.deciding { ", deciding" } else { "" })
    let stopped = ($record | get -o stage | default "")
    let at = (if $stopped == "" { "" } else { $", stopped at its ($stopped)" })
    print $"walk cadence, ($record.mode): ($state)($standing)($at)"
    for f in $record.faults { print $"  ($f.rule): ($f.held), ($f.examples | str join '; ')" }
    for u in $record.unchecked { print $"  unchecked: ($u)" }
    if $record.reading != null {
        let r = $record.reading
        print $"  ($r.frames) frames over ($r.window_s | math round -p 2) s, ended by ($r.ended_by); presents ($r.presents), K violations ($r.k.violations) at eps ($r.k.eps)"
        print $"  frame interval ($r.frame_interval.median_ms) ms median, ($r.frame_interval.p95_ms) 95th; presented ($r.presented_interval.median_ms) and ($r.presented_interval.p95_ms)"
    }
    let pairing = ($record | get -o pairing)
    if $pairing != null {
        let window = ($pairing.window | default {})
        let stalls = ($pairing.stalls.calls | length)
        let framed = ($pairing.stalls.frame | length)
        print $"  pairing ($pairing.verdict) on ($pairing.bound) bounds, ($window | get -o presents) presents of ($window | get -o uploads) uploads; stalls ($stalls), long frames on their brackets ($framed)"
    }
    let flips = ($record | get -o flips)
    if $flips != null {
        print $"  ($flips.shown) of ($flips.presents) shown, ($flips.superseded) superseded, ($flips.repeated) repeats; host flips ($flips.host_interval.median_ms) ms median, ($flips.host_interval.p95_ms) 95th; age ($flips.age.median_ms) ms"
    }
    for s in ($record | get -o stretches | default []) {
        let located = (if $s.located == null { "no phase located, TIMING off" } else { $s.located | str join ", " })
        print $"  stretch at ($s.at_s | math round -p 2) s, frames ($s.first.frame) to ($s.last.frame), ($s.flips) flips, host ($s.host_interval.median_ms) ms median: ($located)"
    }
    for l in $record.limits { print $"  limit: ($l)" }
}

# A probed run read paired, saved
export def main [probe: path, out: path, --eps: int = 10000, --replay: path] {
    let record = (paired-reading $probe --eps $eps --replay $replay)
    write $record $out
    show $record
}

# An unprobed run read from its own records, guest-only, saved
export def guest [run: path, out: path, --eps: int = 10000, --replay: path] {
    let dir = ($run | path expand)
    let identity = (open --raw ($dir | path join "identity.nuon") | into binary | decode | from nuon)
    let api = ($dir | path join "api.out")
    let bytes = (if ($api | path exists) { open --raw $api | into binary } else { 0x[] })
    let record = (guest-reading $bytes $identity --eps $eps --replay $replay)
    write $record $out
    show $record
}

# Every run under a set's tree read guest-only, each saved as <name>.guest.nuon
export def guest-runs [tree: path, out: path, --eps: int = 10000] {
    let root = ($tree | path expand)
    let runs = (glob ($root | path join "**" "api.out") --no-dir | each {|a| $a | path dirname } | where {|d| $d | path join "identity.nuon" | path exists } | sort)
    if ($runs | is-empty) { error make { msg: $"no run under ($root): no directory there holds an api.out and an identity.nuon" } }
    mkdir $out
    for dir in $runs {
        let rel = ($dir | path relative-to $root)
        let name = (if $rel == "" { $root | path basename } else { $rel | path split | str join "_" })
        let identity = (open --raw ($dir | path join "identity.nuon") | into binary | decode | from nuon)
        let record = (guest-reading (open --raw ($dir | path join "api.out") | into binary) $identity --eps $eps)
        write $record ($out | path join $"($name).guest.nuon")
        print $"--- ($name)"
        show $record
    }
}

# A replay stream written from a run's own records
export def replay-of [run: path, stream: path] {
    let bytes = (open --raw ($run | path expand | path join "api.out") | into binary)
    replay-stream $bytes | save --raw $stream
    print $"replay-of: ($stream), (open --raw $stream | into binary | bytes length) bytes"
}
