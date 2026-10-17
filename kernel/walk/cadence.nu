# walk's CADENCE reader: the export a measurement build of example/walk
# sends over its API after its window, read and held to the build's rules.
#
# The stream is the header, the frame records, the event records, and the
# end record (example/walk/srcdoc/main.S.md). It is complete only when its
# header, its end, their counts, and its CRC-32 hold; a fault there ends
# the reading. Past them every rule is held and every fault named and
# counted: the records' own fields, the frames numbered from 0 with no gap
# or repeat, every frame waited, the stamps in the order their build's
# arm gives, no final status of 2, 3, or 4, no event omitted, the events
# and the frames' enters and leaves alike, the window's end the build's
# own (a measurement's by its duration or its event room, a replay's by
# its last frame), a nonce, and a measurement's window of 60 s at least.
# Then the receipt stage, both readings' before anything is computed from
# a receipt: each frame's flip and status agreeing with its receipt, the
# present sequence one past the last from the display's open at 1 (jab
# ordinal-violations), and each presented flip's acceptance at or past
# its tick and inside its call, or inside its frame where the build keeps
# no call's start.
#
# `guest <run dir> <out>` reads an unprobed run from its own api.out and
# identity.nuon, its binding the header's nonce, the identity's
# capture_nonce, and nothing of its presents; its record is guest-only.
# `<probe dir> <out>` reads a probed run's bundle: the bundle checked
# (jab sdl-bundle-check), the program's own nonce read from its api.out,
# then the same reading of the guest's side; the pairing with the host's
# uploads is not read yet, the reading saying so. `replay-of <run dir>
# <stream>` writes a replay stream from a run's own records, its dt values
# the ones the run integrated. `holds <scratch>` runs the reader's
# fixtures over synthetic streams.
use ../../../jab/sdk/nu/jab.nu

const HEADER = 80
const FRAME = 80
const EVENT = 8
const END = 64
const SCHEMA = 4
const MAGIC = 0x44414357
const NO_STATUS = 255
# the kernel's tick, the clock's 10 MHz over the cap's 60
const PERIOD = 166666
const HZ = 10000000
# a measurement's least window, 60 s in ticks
const SHORTEST = 600000000
const TIMING = 1
const REPLAY = 2
const PREPARE = 4
const TEST = 8
const EVENT_ROOM = 16
const REPLAY_MAGIC = 0x4c505257
const REPLAY_HEAD = 64
const ENDS = ["none" "the duration" "the frame buffer" "the event room" "the replay's last frame" "an offset's range"]
const LIMITS = [
    "rdtime is elapsed time: a host stall inside a phase reads as that phase"
    "the guest's records give intervals between its own clock's readings, and nothing of when the host showed a frame"
    "attribution is within a run, by a stretch's own frames against the run's steady medians, never by comparing runs"
]

# A little-endian unsigned word of `size` bytes at `at`, the eight-byte
# one read signed, so a value past 2^63 reads negative.
def le [b: binary, at: int, size: int]: nothing -> int {
    let w = ($b | bytes at $at..<($at + $size))
    if $size == 8 { $w | into int --endian little --signed } else { $w | into int --endian little }
}

# A fault as the reading names it: the rule, how many it held, and up to
# four examples.
def fault [rule: string, held: int, examples: list<string>]: nothing -> record<rule: string, held: int, examples: list<string>> {
    { rule: $rule, held: $held, examples: ($examples | first 4) }
}

# The rows that break a rule as one fault, none when no row does.
def faults-of [rule: string, rows: list<any>, example: closure]: nothing -> list<any> {
    if ($rows | is-empty) { [] } else { [(fault $rule ($rows | length) ($rows | each $example))] }
}

# The CRC-32 of the bytes, IEEE's, through coreutils' cksum.
export def crc-of [bytes: binary]: nothing -> int {
    let r = ($bytes | ^cksum -a crc32b | complete)
    if $r.exit_code != 0 { error make { msg: $"cksum -a crc32b failed: ($r.stderr | str trim)" } }
    $r.stdout | split row " " | first | into int
}

export def header-of [b: binary]: nothing -> record {
    {
        kind: (le $b 0 1), ended: (le $b 1 1), anchors: (le $b 2 2), magic: (le $b 4 4),
        schema: (le $b 8 4), frames: (le $b 12 4), events: (le $b 16 4), rate: (le $b 20 4),
        seed: (le $b 24 8), window: (le $b 32 4), frame_size: (le $b 36 2), event_size: (le $b 38 2),
        flags: (le $b 40 4), trail: (le $b 44 2), size: (le $b 46 2), origin: (le $b 48 8),
        opened: (le $b 56 8), nonce: (le $b 64 8), zero: (le $b 72 8),
    }
}

def end-of [b: binary]: nothing -> record {
    {
        kind: (le $b 0 1), zero_head: ($b | bytes at 1..<4), magic: (le $b 4 4), schema: (le $b 8 4),
        frames: (le $b 12 4), events: (le $b 16 4), crc: (le $b 20 4), omitted: (le $b 24 4),
        zero: ($b | bytes at 28..<64),
    }
}

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

def event-of [b: binary]: nothing -> record {
    { kind: (le $b 0 1), lane: (le $b 1 1), side: (le $b 2 1), scale: (le $b 3 1), tint: (le $b 4 4) }
}

# The flags a header carries, by name.
export def flags-of [flags: int]: nothing -> record<timing: bool, replay: bool, prepare: bool, test: bool, event_room: bool> {
    {
        timing: (($flags bit-and $TIMING) != 0), replay: (($flags bit-and $REPLAY) != 0),
        prepare: (($flags bit-and $PREPARE) != 0), test: (($flags bit-and $TEST) != 0),
        event_room: (($flags bit-and $EVENT_ROOM) != 0),
    }
}

# The stream read whole and held to its rules (the reading's first step).
# A fault in its header, its length, its end record, their counts, or its
# CRC ends the reading there; past them the records are read and every
# rule held, each fault named and counted. `test` admits a CADENCE_TEST
# build, whose window its own test reads; a measurement takes no test
# build. `complete` when no fault ends the reading, the faults beside it.
export def stream-of [bytes: binary, --test]: nothing -> record {
    let size = ($bytes | bytes length)
    let ended = {|f: record| { complete: false, faults: [$f], header: null, frames: [], events: [], end: null } }
    if $size < $HEADER { return (do $ended (fault "no header" 1 [$"the stream is ($size) bytes"])) }
    let h = (header-of ($bytes | bytes at 0..<$HEADER))
    let wrong = ([
        (if $h.kind != 4 { $"kind ($h.kind)" })
        (if $h.magic != $MAGIC { $"magic 0x($h.magic | format number | get lowerhex | str substring 2..)" })
        (if $h.schema != $SCHEMA { $"schema ($h.schema)" })
        (if $h.size != $HEADER { $"a header of ($h.size) bytes" })
        (if $h.frame_size != $FRAME { $"frame records of ($h.frame_size) bytes" })
        (if $h.event_size != $EVENT { $"event records of ($h.event_size) bytes" })
        (if $h.zero != 0 { "bytes 72 to 79 not zero" })
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
    let fl = (flags-of $h.flags)
    let at = {|f: record| $"frame ($f.frame)" }
    let indexed = ($frames | enumerate)
    let last = ($frames | last)
    let window = (if $last == null { 0 } else { $last.call_end })
    let enters = ($frames | get -o enters | default [] | math sum)
    let leaves = ($frames | get -o leaves | default [] | math sum)
    let entered = ($events | where kind == 1 | length)
    let left = ($events | where kind == 2 | length)
    let ends = (if $fl.replay { [4] } else { [1 3] })
    let faults = ([
        (faults-of "the record" ($frames | where {|f| $f.kind != 1 or $f.schema != $SCHEMA or $f.pad != 0 or $f.issued not-in [0 1] or $f.status not-in [0 1 2 3 4 $NO_STATUS] }) $at)
        (faults-of "the numbering" ($indexed | where {|r| $r.item.frame != $r.index }) {|r| $"record ($r.index) numbered ($r.item.frame)" })
        (faults-of "the wait" ($frames | where {|f| $f.waited != 1 }) $at)
        (faults-of "the final status" ($frames | where {|f| $f.status in [2 3 4] }) {|f| $"frame ($f.frame) status ($f.status)" })
        (if $fl.timing { phase-faults $frames $fl.prepare } else { untimed-faults $frames })
        (faults-of "the events" ($events | where {|v| $v.kind not-in [1 2] or $v.lane >= 8 }) {|v| $"kind ($v.kind) lane ($v.lane)" })
        (if $e.omitted > 0 { [(fault "an event omitted" $e.omitted [$"($e.omitted) past the buffer"])] } else { [] })
        (if $e.omitted == 0 and ($enters != $entered or $leaves != $left) { [(fault "the events' counts" 1 [$"the frames count ($enters) enters and ($leaves) leaves, the events ($entered) and ($left)"])] } else { [] })
        (if $h.ended not-in $ends { [(fault "the window's end" 1 [$"ended by ((if $h.ended < ($ENDS | length) { $ENDS | get $h.ended } else { $'end ($h.ended)' })), where a ((if $fl.replay { 'replay' } else { 'measurement' })) ends by ($ends | each {|x| $ENDS | get $x } | str join ' or ')"])] } else { [] })
        (if $h.nonce == 0 { [(fault "the nonce" 1 ["the header's capture nonce is 0"])] } else { [] })
        (if $fl.test and not $test { [(fault "a test build" 1 ["a CADENCE_TEST build, read by its own test alone"])] } else { [] })
        (if (not $fl.replay) and (not $fl.test) and $window < $SHORTEST { [(fault "a short window" 1 [$"($window / $HZ) s of window, 60 s the least"])] } else { [] })
        (if $h.frames == 0 { [(fault "no frame" 1 ["the window holds no frame"])] } else { [] })
    ] | reduce --fold [] {|x, acc| $acc ++ $x })
    { complete: true, faults: $faults, header: $h, frames: $frames, events: $events, end: $e }
}

# Whether every byte is zero.
def zeroed [b: binary]: nothing -> bool {
    ($b | bytes replace --all 0x[00] 0x[] | bytes length) == 0
}

# A TIMING build's frames out of their phase order: walk's, the wait's
# start, its end, the frame's start, the work's end, the call's start, its
# end; PREPARE's, the frame's start, the work's end, the wait's start, its
# end, the call's start, its end; and each frame's start at or past the
# frame before's call's end.
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

# A build without TIMING: its four fields zero, and each frame's start at
# or before its call's end, that end at or before the next frame's start.
def untimed-faults [frames: list<record>]: nothing -> list<any> {
    let fields = ($frames | where {|f| $f.wait_start != 0 or $f.wait_end != 0 or $f.work_end != 0 or $f.call_start != 0 })
    let order = ($frames | enumerate | where {|r|
        let next = ($frames | get -o ($r.index + 1))
        $r.item.start > $r.item.call_end or ($next != null and $r.item.call_end > $next.start)
    })
    (faults-of "a TIMING field without TIMING" $fields {|f| $"frame ($f.frame)" }) ++ (faults-of "the stamps' order" $order {|r| $"frame ($r.item.frame)" })
}

# The receipt stage, every reading's before anything is computed from a
# receipt: a frame with no flip issued carries NO_STATUS, s 0, and T 0,
# and one with a flip issued a status, s and T nonzero with a 0 or a 1, a
# 2 to 4 being the stream's own refusals; the
# present sequence from the display's open at 1 (jab
# ordinal-violations), a presented flip one past the last and every other
# frame the last, a failed present's 3 taken as presented where its
# ordinal moved on by one, since its flush can be acknowledged after a
# refused transfer; and each presented flip's s at or past its T and inside
# its call, the call's start and end with TIMING, the frame's start and
# the call's end without it. Every fault named and counted.
export def receipt-faults [frames: list<record>, origin: int, timing: bool]: nothing -> list<any> {
    let issue = ($frames | where {|f|
        if $f.issued == 0 { $f.status != $NO_STATUS or $f.s != 0 or $f.t != 0 } else if $f.status in [0 1] { $f.s == 0 or $f.t == 0 } else { $f.status == $NO_STATUS }
    })
    let presents = ($frames | enumerate | each {|r|
        let f = $r.item
        let before = (if $r.index == 0 { 1 } else { $frames | get ($r.index - 1) | get ordinal })
        { presented: ($f.issued == 1 and ($f.status == 0 or ($f.status == 3 and $f.ordinal == $before + 1))), ordinal: $f.ordinal }
    })
    let violations = (jab ordinal-violations 1 $presents)
    let ordinals = ($violations | group-by rule | items {|rule, rows| fault $"the present sequence: ($rule)" ($rows | length) ($rows | each {|v| $"frame ($v.index) at ($v.ordinal), ($v.wanted) wanted" }) } | default [])
    let accepted = ($frames | where {|f| $f.issued == 1 and $f.status == 0 } | where {|f|
        let low = ($origin + (if $timing { $f.call_start } else { $f.start }))
        let high = ($origin + $f.call_end)
        $f.s < $f.t or $f.s < $low or $f.s > $high
    })
    (faults-of "the receipt's flip" $issue {|f| $"frame ($f.frame): issued ($f.issued), status ($f.status), s ($f.s), T ($f.t)" }) ++ ($ordinals | sort-by rule) ++ (faults-of "the acceptance" $accepted {|f| $"frame ($f.frame): s ($f.s), T ($f.t)" })
}

# The nearest-rank percentile of the values, null for none.
def rank [values: list<number>, p: float]: nothing -> any {
    if ($values | is-empty) { return null }
    let sorted = ($values | sort)
    let i = ([((($p * ($sorted | length)) | math ceil) - 1) 0] | math max)
    $sorted | get $i
}

# A distribution's median and 95th in milliseconds, from ticks.
def spread [ticks: list<number>]: nothing -> record<median_ms: any, p95_ms: any, count: int> {
    let ms = ($ticks | each {|t| $t / 10000.0 })
    { median_ms: (rank $ms 0.5), p95_ms: (rank $ms 0.95), count: ($ms | length) }
}

# The guest's side of a reading (the fifth step), on a stream that held:
# each frame's interval, start to start, in either arm; with TIMING the
# work, the wait, and the call, each frame's own, without it unavailable,
# null and never zero; the presented intervals from the receipts'
# acceptances; K over them (jab k-violations, `eps` in ticks), reported
# and never the run's validity; and the workload.
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
    let k = (jab k-violations $accepted $PERIOD $eps)
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

# A guest-only reading: the stream's rules but the capture's, the receipt
# stage, and the binding, the header's capture nonce equal to the
# identity's `capture_nonce` and nonzero; then the guest's side. Marked
# guest-only, so no stretch's attribution takes it.
export def guest-reading [bytes: binary, identity: record, --eps: int = 10000, --test]: nothing -> record {
    let stream = (stream-of $bytes --test=$test)
    let base = { reader: "walk cadence", mode: "guest", guest_only: true, limits: $LIMITS }
    if not $stream.complete { return ($base | merge { complete: false, valid: false, faults: $stream.faults, reading: null }) }
    let receipts = (if ($stream.frames | is-empty) { [] } else { receipt-faults $stream.frames $stream.header.origin (flags-of $stream.header.flags).timing })
    let wanted = ($identity | get -o capture_nonce)
    let binding = (if $wanted == null or $wanted == 0 or $wanted != $stream.header.nonce {
        [(fault "the binding" 1 [$"the header's nonce ($stream.header.nonce), the identity's ($wanted | to nuon)"])]
    } else { [] })
    let faults = ($stream.faults ++ $receipts ++ $binding)
    let valid = ($faults | is-empty)
    $base | merge { complete: true, valid: $valid, faults: $faults, nonce: $stream.header.nonce, reading: (if $valid { guest-side $stream $eps } else { null }) }
}

# The header's capture nonce from an export's bytes, what a paired
# bundle's check takes as the guest's echo; null for a stream too short
# to hold its header.
export def header-nonce [bytes: binary]: nothing -> any {
    if ($bytes | bytes length) < $HEADER { return null }
    (header-of ($bytes | bytes at 0..<$HEADER)).nonce
}

# A replay stream from a run's own records, which must read complete and
# valid: the header, WRPL, schema 1, the frames, the run's seed, and the
# SHA-256 of the run's export, then each frame's dt, the value the run
# integrated, never its raw elapsed.
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

# A replay run's workload held to its reference's frame for frame, the
# walkers, the rectangles and their area, the drawn area, the enters, and
# the leaves; every difference a fault, and a count other than the
# reference's one.
export def replay-faults [replay: list<record>, reference: list<record>]: nothing -> list<any> {
    let fields = [walkers rects rect_area drawn enters leaves]
    if ($replay | length) != ($reference | length) { return [(fault "the replay's frames" 1 [$"($replay | length) frames, the reference's ($reference | length)"])] }
    let differ = ($replay | zip $reference | enumerate | where {|r| $fields | any {|k| ($r.item.0 | get $k) != ($r.item.1 | get $k) } })
    faults-of "the replay's workload" $differ {|r| $"frame ($r.index)" }
}

# A stretch's attribution takes a paired reading alone: a guest-only
# record has no host side to locate a stretch in.
export def stretches-of [reading: record]: nothing -> any {
    if ($reading | get -o guest_only | default false) { error make { msg: "a guest-only reading has no host side: its stretches are not attributed" } }
    if ($reading | get -o pairing) == null { error make { msg: "the reading holds no pairing: its stretches are not attributed" } }
    error make { msg: "the stretches wait on the pairing's reading" }
}

def write [record: record, out: path]: nothing -> nothing {
    $record | to nuon --indent 1 | save --raw -f $out
}

def show [record: record]: nothing -> nothing {
    let state = (if $record.valid { "valid" } else if $record.complete { "invalid" } else { "incomplete" })
    print $"walk cadence, ($record.mode): ($state)"
    for f in $record.faults { print $"  ($f.rule): ($f.held), ($f.examples | str join '; ')" }
    if $record.reading != null {
        let r = $record.reading
        print $"  ($r.frames) frames over ($r.window_s | math round -p 2) s, ended by ($r.ended_by); presents ($r.presents), K violations ($r.k.violations) at eps ($r.k.eps)"
        print $"  frame interval ($r.frame_interval.median_ms) ms median, ($r.frame_interval.p95_ms) 95th; presented ($r.presented_interval.median_ms) and ($r.presented_interval.p95_ms)"
    }
    for l in $record.limits { print $"  limit: ($l)" }
}

def main [probe: path, out: path, --eps: int = 10000] {
    let dir = ($probe | path expand)
    let bundle = ($dir | path join "bundle")
    let checked = (jab sdl-bundle-check $bundle --guest {|api| header-nonce (open --raw $api | into binary) })
    let identity = (open --raw ($bundle | path join "identity.nuon") | into binary | decode | from nuon)
    let guest = (guest-reading (open --raw ($bundle | path join "api.out") | into binary) $identity --eps $eps)
    let record = ($guest | merge { mode: "paired", guest_only: false, capture: ($checked | reject events), pairing: null, pending: "the pairing with the host's uploads is not read yet" })
    write $record $out
    show $record
}

def "main guest" [run: path, out: path, --eps: int = 10000] {
    let dir = ($run | path expand)
    let identity = (open --raw ($dir | path join "identity.nuon") | into binary | decode | from nuon)
    let api = ($dir | path join "api.out")
    let bytes = (if ($api | path exists) { open --raw $api | into binary } else { 0x[] })
    let record = (guest-reading $bytes $identity --eps $eps)
    write $record $out
    show $record
}

def "main replay-of" [run: path, stream: path] {
    let bytes = (open --raw ($run | path expand | path join "api.out") | into binary)
    replay-stream $bytes | save --raw $stream
    print $"replay-of: ($stream), (open --raw $stream | into binary | bytes length) bytes"
}

# A little-endian word of `size` bytes.
def word [v: int, size: int]: nothing -> binary {
    $v | into binary --endian little | bytes at 0..<$size
}

# A frame record's bytes from its fields, each given over a presented
# frame's defaults.
def frame-bytes [f: record]: nothing -> binary {
    let d = ({
        kind: 1, issued: 1, status: 0, walkers: 3, frame: 0, start: 0, call_end: 0, wait_start: 0,
        wait_end: 0, work_end: 0, call_start: 0, raw: $HZ, dt: 1000000, rects: 3, enters: 0, leaves: 0,
        rect_area: 30000, s: 0, t: 0, ordinal: 2, drawn: 20000, waited: 1, pad: 0, schema: $SCHEMA,
    } | merge $f)
    [
        (word $d.kind 1) (word $d.issued 1) (word $d.status 1) (word $d.walkers 1)
        (word $d.frame 4) (word $d.start 4) (word $d.call_end 4) (word $d.wait_start 4)
        (word $d.wait_end 4) (word $d.work_end 4) (word $d.call_start 4) (word $d.raw 4)
        (word $d.dt 4) (word $d.rects 2) (word $d.enters 1) (word $d.leaves 1)
        (word $d.rect_area 4) (word $d.s 8) (word $d.t 8) (word $d.ordinal 4)
        (word $d.drawn 4) (word $d.waited 1) (word $d.pad 3) (word $d.schema 4)
    ] | bytes collect
}

# A synthetic export for the reader's own fixtures: the header's fields
# over a measurement's defaults, its frames and events, and the end's
# fields, its CRC computed over the records unless `end` gives one, as a
# byte fault's stale CRC does.
export def synth [spec: record]: nothing -> binary {
    let frames = $spec.frames
    let events = ($spec | get -o events | default [])
    let h = ({
        kind: 4, ended: 1, anchors: 30, magic: $MAGIC, schema: $SCHEMA, frames: ($frames | length),
        events: ($events | length), rate: $HZ, seed: 1, window: 1200000000, frame_size: $FRAME,
        event_size: $EVENT, flags: $TIMING, trail: 60, size: $HEADER, origin: 1000000000,
        opened: 990000000, nonce: 77, zero: 0,
    } | merge ($spec | get -o header | default {}))
    let head = ([
        (word $h.kind 1) (word $h.ended 1) (word $h.anchors 2) (word $h.magic 4)
        (word $h.schema 4) (word $h.frames 4) (word $h.events 4) (word $h.rate 4)
        (word $h.seed 8) (word $h.window 4) (word $h.frame_size 2) (word $h.event_size 2)
        (word $h.flags 4) (word $h.trail 2) (word $h.size 2) (word $h.origin 8)
        (word $h.opened 8) (word $h.nonce 8) (word $h.zero 8)
    ] | bytes collect)
    let body = ($frames | each {|f| frame-bytes $f } | bytes collect)
    let evs = ($events | each {|v| [(word $v.kind 1) (word $v.lane 1) (word ($v | get -o side | default 0) 1) (word ($v | get -o scale | default 60) 1) (word ($v | get -o tint | default 0) 4)] | bytes collect } | bytes collect)
    let records = ($head ++ $body ++ $evs)
    let e = ({ kind: 5, frames: $h.frames, events: $h.events, omitted: 0, crc: null } | merge ($spec | get -o end | default {}))
    let crc = (if $e.crc == null { crc-of $records } else { $e.crc })
    $records ++ ([(word $e.kind 1) (word 0 3) (word $MAGIC 4) (word $SCHEMA 4) (word $e.frames 4) (word $e.events 4) (word $crc 4) (word $e.omitted 4) (word 0 8) (word 0 8) (word 0 8) (word 0 8) (word 0 4)] | bytes collect)
}

# A valid window for the fixtures: `n` frames a second apart, every one
# presented, its ordinals 2 on, in walk's order or PREPARE's, with or
# without TIMING; each acceptance 10 ticks into its call, its tick at the
# call's start.
export def window-of [n: int, --prepare, --untimed, --origin: int = 1000000000]: nothing -> list<record> {
    0..<$n | each {|i|
        let b = ($i * $HZ)
        let stamps = (if $prepare {
            { start: $b, work_end: ($b + 50000), wait_start: ($b + 50020), wait_end: ($b + 166666), call_start: ($b + 166676), call_end: ($b + 181676) }
        } else {
            { wait_start: $b, wait_end: ($b + 1000), start: ($b + 1010), work_end: ($b + 51010), call_start: ($b + 51020), call_end: ($b + 66020) }
        })
        let receipt = { issued: 1, status: 0, rects: 3, s: ($origin + $stamps.call_start + 10), t: ($origin + $stamps.call_start), ordinal: ($i + 2), frame: $i }
        let timed = (if $untimed { $stamps | merge { wait_start: 0, wait_end: 0, work_end: 0, call_start: 0 } } else { $stamps })
        $timed | merge $receipt
    }
}

# A frame of a window that issued no flip: its receipt empty, its
# ordinal the one given, its call's two stamps the skip's one.
def unflipped [f: record, ordinal: int, timed: bool]: nothing -> record {
    let skip = (if $timed { { call_start: $f.call_end } } else { {} })
    $f | merge { issued: 0, status: $NO_STATUS, s: 0, t: 0, ordinal: $ordinal, rects: 0, rect_area: 0 } | merge $skip
}

# The reader's own fixtures over synthetic streams, each case's failure
# raised with its name: every admitted shape read valid with its values
# exact, and every refusal its own rule's alone, each negative's CRC
# recomputed so only that rule can refuse it, the byte fault's left stale.
def "main holds" [scratch: path] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    mkdir $scratch
    let fail = {|name: string, why: string| error make { msg: $"cadence holds: ($name): ($why)" } }
    let id = { capture_nonce: 77 }
    let read = {|spec: record, test: bool| guest-reading (synth $spec) $id --test=$test }
    let admit = {|name: string, r: record|
        if not $r.valid { do $fail $name $"refused: ($r.faults | to nuon)" }
        $r
    }
    let refuse = {|name: string, r: record, rules: list<string>|
        if $r.valid { do $fail $name "admitted" }
        let got = ($r.faults | get rule | sort)
        if $got != ($rules | sort) { do $fail $name $"refused by ($got | to nuon), where ($rules | to nuon)" }
    }
    let w = (window-of 61)

    # admitted, each arm and order, values exact; PREPARE's first, where a
    # drawing taken from the wait's end reads negative
    let prep = (do $admit "TIMING on, PREPARE's order" (do $read { frames: (window-of 61 --prepare), header: { flags: ($TIMING bit-or $PREPARE) } } false))
    if $prep.reading.phases.work.median_ms != 5.0 or $prep.reading.phases.wait.median_ms != 11.6646 { do $fail "PREPARE's drawing" $"work ($prep.reading.phases.work.median_ms), wait ($prep.reading.phases.wait.median_ms)" }
    let on = (do $admit "TIMING on, walk's order" (do $read { frames: $w } false))
    if $on.reading.phases.work.median_ms != 5.0 { do $fail "TIMING on, walk's order" $"work ($on.reading.phases.work.median_ms) ms" }
    if $on.reading.phases.call.median_ms != 1.5 { do $fail "TIMING on, walk's order" $"call ($on.reading.phases.call.median_ms) ms" }
    if ($w | first | get wait_start) != 0 { do $fail "the first stamp at the origin" "frame 0's wait does not start at the origin" }
    let off = (do $admit "TIMING off" (do $read { frames: (window-of 61 --untimed), header: { flags: 0 } } false))
    if $off.reading.phases != { work: null, wait: null, call: null } { do $fail "TIMING off" $"its phases read ($off.reading.phases | to nuon), never zero" }
    do $admit "TIMING off, PREPARE's order" (do $read { frames: (window-of 61 --prepare --untimed), header: { flags: $PREPARE } } false) | ignore
    if $on.reading.k.violations != 0 { do $fail "K at a second apart" $"($on.reading.k.violations) violations" }

    # a replay past where an i32 offset wraps, s and T exact
    let long = (window-of 220)
    let replay = (do $admit "a replay past 214.7483647 s" (do $read { frames: $long, header: { flags: ($TIMING bit-or $REPLAY), ended: 4, window: 0 } } false))
    let past = (stream-of (synth { frames: $long, header: { flags: ($TIMING bit-or $REPLAY), ended: 4, window: 0 } }))
    let late = ($past.frames | last)
    if $late.s != (1000000000 + 219 * $HZ + 51030) or $late.t != (1000000000 + 219 * $HZ + 51020) or $late.call_end <= 2147483648 { do $fail "a replay past 214.7483647 s" $"s ($late.s), T ($late.t), end ($late.call_end)" }
    if $replay.reading.window_s <= 214.7483647 { do $fail "a replay past 214.7483647 s" $"window ($replay.reading.window_s)" }

    # replay-of: the dt the reference integrated, never its raw elapsed
    let clamped = ($w | enumerate | each {|r| if $r.index == 30 { $r.item | merge { raw: 1500000, dt: 1000000 } } else { $r.item | merge { raw: (1000000 + $r.index), dt: (900000 + $r.index) } } })
    let stream = (replay-stream (synth { frames: $clamped }))
    let dts = (0..<61 | each {|i| le $stream ($REPLAY_HEAD + $i * 4) 4 })
    if $dts != ($clamped | get dt) { do $fail "replay-of" $"its dt values are not the reference's at 36: ($dts | first 3)" }
    if (le $stream 0 4) != $REPLAY_MAGIC or (le $stream 8 4) != 61 or (le $stream 16 8) != 1 { do $fail "replay-of" "its header" }
    if ($stream | bytes at 32..<64) != (synth { frames: $clamped } | hash sha256 --binary) { do $fail "replay-of" "its reference's SHA-256" }

    # the replay's workload, frame for frame
    let ref_frames = (stream-of (synth { frames: $w })).frames
    let same = (replay-faults $ref_frames $ref_frames)
    if not ($same | is-empty) { do $fail "a replay's own workload" ($same | to nuon) }
    let moved = (replay-faults ($ref_frames | enumerate | each {|r| if $r.index == 30 { $r.item | update drawn 1 } else { $r.item } }) $ref_frames)
    if ($moved | get rule) != ["the replay's workload"] { do $fail "a replay's workload differing" ($moved | to nuon) }

    # refused, each by its own rule
    do $refuse "the end's counts" (do $read { frames: $w, end: { frames: 62 } } false) ["the end's counts"]
    do $refuse "a missing frame number" (do $read { frames: ($w | enumerate | each {|r| if $r.index >= 30 { $r.item | update frame ($r.index + 1) } else { $r.item } }) } false) ["the numbering"]
    do $refuse "a repeated frame number" (do $read { frames: ($w | enumerate | each {|r| if $r.index == 31 { $r.item | update frame 30 } else { $r.item } }) } false) ["the numbering"]
    do $refuse "an omitted event" (do $read { frames: $w, end: { omitted: 1 } } false) ["an event omitted"]
    do $admit "a measurement ended by its event room" (do $read { frames: $w, header: { ended: 3 } } false) | ignore
    do $refuse "a frame buffer ending the window" (do $read { frames: $w, header: { ended: 2 } } false) ["the window's end"]
    do $refuse "ended_by 5" (do $read { frames: $w, header: { ended: 5 } } false) ["the window's end"]
    do $refuse "a short window" (do $read { frames: (window-of 60) } false) ["a short window"]
    do $refuse "a replay ended by the event room" (do $read { frames: $w, header: { flags: ($TIMING bit-or $REPLAY), ended: 3, window: 0 } } false) ["the window's end"]
    do $refuse "a replay ended by its bound, nothing exported" (guest-reading 0x[] $id) ["no header"]
    do $refuse "a TIMING field without TIMING" (do $read { frames: ((window-of 61 --untimed) | enumerate | each {|r| if $r.index == 5 { $r.item | update work_end 1 } else { $r.item } }), header: { flags: 0 } } false) ["a TIMING field without TIMING"]
    do $refuse "a TIMING frame out of its order" (do $read { frames: ($w | enumerate | each {|r| if $r.index == 5 { $r.item | update work_end ($r.item.start - 1) } else { $r.item } }) } false) ["the phase order"]
    do $refuse "a final status of 3" (do $read { frames: ($w | enumerate | each {|r| if $r.index == 5 { $r.item | update status 3 } else { $r.item } }) } false) ["the final status"]
    let good = (synth { frames: $w })
    let flipped = ($good | bytes at 0..<(($HEADER + 5 * $FRAME) + 44)) ++ 0x[ff] ++ ($good | bytes at (($HEADER + 5 * $FRAME) + 45)..)
    do $refuse "a byte fault, the CRC stale" (guest-reading $flipped $id) ["the CRC"]
    do $refuse "no end record, an interrupted export (exit 4)" (guest-reading ($good | bytes at 0..<($HEADER + 20 * $FRAME)) $id) ["no end record"]
    do $refuse "no end record, no port (exit 3)" (guest-reading 0x[] $id) ["no header"]
    do $refuse "a test build read as a measurement" (do $read { frames: $w, header: { flags: ($TIMING bit-or $TEST) } } false) ["a test build"]
    do $admit "a test build read by its test" (do $read { frames: (window-of 11), header: { flags: ($TIMING bit-or $TEST) } } true) | ignore

    # the guest-only binding, and the attribution refusing its record
    do $refuse "a nonce other than the identity's" (guest-reading (synth { frames: $w, header: { nonce: 78 } }) $id) ["the binding"]
    do $refuse "a nonce of 0" (guest-reading (synth { frames: $w, header: { nonce: 0 } }) $id) ["the binding" "the nonce"]
    let attributed = (try { stretches-of $on; "attributed" } catch {|e| $e.msg })
    if not ($attributed | str contains "guest-only") { do $fail "the attribution of a guest-only record" $attributed }

    # the receipt stage on guest-only streams
    let ords = {|ordinals: list<int>| $w | enumerate | each {|r| if $r.index < ($ordinals | length) { $r.item | update ordinal ($ordinals | get $r.index) } else { $r.item | update ordinal ($r.item.ordinal + (($ordinals | last) - ($ordinals | length) - 1)) } } }
    do $refuse "presents at 2, 4, 5" (do $read { frames: (do $ords [2 4 5]) } false) ["the present sequence: skip"]
    do $refuse "presents at 2, 3, 3" (do $read { frames: (do $ords [2 3 3 4 5]) } false) ["the present sequence: repeat"]
    do $refuse "presents at 2, 3, 2" (do $read { frames: (do $ords [2 3 2 3 4 5]) } false) ["the present sequence: backward"]
    do $refuse "a first present at 3" (do $read { frames: (do $ords [3]) } false) ["the present sequence: skip"]
    let held = ($w | enumerate | each {|r| if $r.index <= 1 { unflipped $r.item 1 true } else { $r.item | update ordinal ($r.index) } })
    do $admit "frames without a flip at the last ordinal" (do $read { frames: $held } false) | ignore
    let refused_flip = ($w | enumerate | each {|r| if $r.index == 5 { $r.item | merge { status: 1, ordinal: 6, t: ($r.item.s + 5) } } else if $r.index > 5 { $r.item | update ordinal ($r.index + 1) } else { $r.item } })
    do $admit "an early refusal at the last ordinal" (do $read { frames: $refused_flip } false) | ignore
    do $admit "a list of three rectangles advancing by one" (do $read { frames: ($w | each {|f| $f | update rects 3 }) } false) | ignore
    do $refuse "a frame without a flip advancing" (do $read { frames: ($held | enumerate | each {|r| if $r.index == 1 { $r.item | update ordinal 2 } else if $r.index > 1 { $r.item | update ordinal ($r.index + 1) } else { $r.item } }) } false) ["the present sequence: advance"]
    do $refuse "an early refusal advancing" (do $read { frames: ($w | enumerate | each {|r| if $r.index == 5 { $r.item | merge { status: 1, t: ($r.item.s + 5) } } else { $r.item } }) } false) ["the present sequence: advance"]
    do $refuse "no flip, a status of 0" (do $read { frames: ($held | enumerate | each {|r| if $r.index == 0 { $r.item | update status 0 } else { $r.item } }) } false) ["the receipt's flip"]
    do $refuse "no flip, a nonzero s" (do $read { frames: ($held | enumerate | each {|r| if $r.index == 0 { $r.item | update s 5 } else { $r.item } }) } false) ["the receipt's flip"]
    do $refuse "no flip, a nonzero T" (do $read { frames: ($held | enumerate | each {|r| if $r.index == 0 { $r.item | update t 5 } else { $r.item } }) } false) ["the receipt's flip"]
    do $refuse "a flip issued with no status" (do $read { frames: ($w | enumerate | each {|r| if $r.index == 5 { $r.item | merge { status: $NO_STATUS, ordinal: 6 } } else if $r.index > 5 { $r.item | update ordinal ($r.index + 1) } else { $r.item } }) } false) ["the receipt's flip"]
    do $refuse "an acceptance before its tick" (do $read { frames: ($w | enumerate | each {|r| if $r.index == 5 { $r.item | update t ($r.item.s + 1) } else { $r.item } }) } false) ["the acceptance"]
    do $refuse "an acceptance outside its call" (do $read { frames: ($w | enumerate | each {|r| if $r.index == 5 { $r.item | update s (1000000000 + $r.item.call_end + 1) } else { $r.item } }) } false) ["the acceptance"]
    print "cadence holds: ok"
}
