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
export const NO_STATUS = 255

# The clock's ticks a second, the one rate the reader reads
export const HZ = 10000000

# A measurement's least window, 60 s in ticks
const SHORTEST = 600000000

# A measurement's window, 120 s in ticks
const WINDOW = 1200000000

# A CADENCE_TEST build's window, 10 s in ticks
const TEST_WINDOW = 100000000

# The most frames a window holds, walk's frame buffer
export const FRAMES_MAX = 8192

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

# What can end a window, by the header's code
export const ENDS = ["none" "the duration" "the frame buffer" "the event room" "the replay's last frame" "an offset's range"]

# A little-endian word of `size` bytes at `at`, the eight-byte one signed
export def le [b: binary, at: int, size: int]: nothing -> int {
    let w = ($b | bytes at $at..<($at + $size))
    if $size == 8 { $w | into int --endian little --signed } else { $w | into int --endian little }
}

# A fault as the reading names it: rule, count, and examples
export def fault [rule: string, held: int, examples: list<string>]: nothing -> record<rule: string, held: int, examples: list<string>> {
    { rule: $rule, held: $held, examples: ($examples | first 4) }
}

# The rows that break a rule as one fault, none when no row does
export def faults-of [rule: string, rows: list<any>, example: closure]: nothing -> list<any> {
    if ($rows | is-empty) { [] } else { [(fault $rule ($rows | length) ($rows | each $example))] }
}

# Lists of faults joined in order
export def joined [lists: list<any>]: nothing -> list<any> {
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

# The header's capture nonce from an export's bytes, null if too short
export def header-nonce [bytes: binary]: nothing -> any {
    if ($bytes | bytes length) < $HEADER { return null }
    (header-of ($bytes | bytes at 0..<$HEADER)).nonce
}
