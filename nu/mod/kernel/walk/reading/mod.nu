use (path self ../../../../../../jab/nu/mod/present)
use (path self ../replay) [replay-bound-faults]
use (path self ../stream) [ENDS HZ NO_STATUS fault faults-of flags-of joined stream-of]

# The kernel's tick, the clock's 10 MHz over the cap's 60
const PERIOD = 166666

# Each header flag's build symbol
const SYMBOLS = { timing: "TIMING", replay: "REPLAY", prepare: "PREPARE", test: "CADENCE_TEST", event_room: "EVENT_ROOM" }

# The fields an identity names its build by
const BUILD_FIELDS = [cadence flags image kernel workload]

# The stream's rules a receipt sequence needs before its K is read
const CONTRACT_RULES = ["the record" "the numbering" "the final status" "the nonce" "no frame"]

# What a historical reading, its identity naming no build, leaves unchecked
const HISTORICAL_UNCHECKED = [
    "the arm: the header's flags against the build's symbols"
    "the build: its image's and its kernel's SHA-256"
    "the window's field and the events' bound against the build's, held to the header's own flags alone"
]

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

# The identity's build held to the header; one naming none read as historical
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
export def rank [values: list<number>, p: float]: nothing -> any {
    if ($values | is-empty) { return null }
    let sorted = ($values | sort)
    let i = ([((($p * ($sorted | length)) | math ceil) - 1) 0] | math max)
    $sorted | get $i
}

# Ticks in milliseconds, null kept
export def ms [ticks: any]: nothing -> any {
    if $ticks == null { null } else { $ticks / 10000.0 }
}

# A distribution's median and 95th in milliseconds, from ticks
export def spread [ticks: list<number>]: nothing -> record<median_ms: any, p95_ms: any, count: int> {
    let ms = ($ticks | each {|t| $t / 10000.0 })
    { median_ms: (rank $ms 0.5), p95_ms: (rank $ms 0.95), count: ($ms | length) }
}

# A distribution's median and 95th in milliseconds, from microseconds
export def spread-us [us: list<number>]: nothing -> record<median_ms: any, p95_ms: any, count: int> {
    let ms = ($us | each {|t| $t / 1000.0 })
    { median_ms: (rank $ms 0.5), p95_ms: (rank $ms 0.95), count: ($ms | length) }
}

# K over a stream's receipt sequence where it can be trusted, else its reason
export def contract-of [stream: record, held: list<any>, eps: int]: nothing -> record<available: bool, reason: string, k: any> {
    if not $stream.complete {
        return { available: false, reason: $"the stream: ($stream.faults | each {|f| $f.rule } | str join ', ')", k: null }
    }
    let faults = (($stream.faults | where {|f| $f.rule in $CONTRACT_RULES }) ++ $held)
    if not ($faults | is-empty) {
        return { available: false, reason: ($faults | each {|f| $f.rule } | uniq | str join ", "), k: null }
    }
    let accepted = ($stream.frames | where {|f| $f.issued == 1 and $f.status == 0 } | each {|f| $f.s })
    let k = (present k-violations $accepted $PERIOD $eps)
    { available: true, reason: "", k: { eps: $eps, period: $PERIOD, violations: ($k | length), first: ($k | first 8) } }
}

# The guest's side of a reading, on a stream that held, its contract's K
export def guest-side [stream: record, k: record]: nothing -> record {
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
        k: $k,
        workload: {
            drawn: { median: (rank ($frames | get drawn) 0.5), p95: (rank ($frames | get drawn) 0.95) },
            rect_area: { median: (rank ($frames | get rect_area) 0.5), p95: (rank ($frames | get rect_area) 0.95) },
            enters_per_s: (if $window_s > 0 { ($frames | get enters | math sum) / $window_s } else { null }),
        },
    }
}

# A stream read on the path both readings take: rules, receipts, binding, build
export def guest-of [bytes: binary, identity: record, eps: int, test: bool, replay: any]: nothing -> record<result: record, stream: record> {
    let stream = (stream-of $bytes --test=$test)
    let base = { reader: "walk cadence", mode: "guest", guest_only: true }
    if not $stream.complete {
        return { result: ($base | merge { complete: false, valid: false, faults: $stream.faults, nonce: null, historical: null, deciding: false, build: null, unchecked: [], contract: (contract-of $stream [] $eps), reading: null }), stream: $stream }
    }
    let receipts = (if ($stream.frames | is-empty) { [] } else { receipt-faults $stream.frames $stream.header.origin (flags-of $stream.header.flags).timing })
    let wanted = ($identity | get -o capture_nonce)
    let binding = (if $wanted == null or $wanted == 0 or $wanted != $stream.header.nonce {
        [(fault "the binding" 1 [$"the header's nonce ($stream.header.nonce), the identity's ($wanted | to nuon)"])]
    } else { [] })
    let contract = (contract-of $stream ($receipts ++ $binding) $eps)
    let built = (identity-stage $stream $identity $replay)
    let faults = ($stream.faults ++ $receipts ++ $binding ++ $built.faults)
    let valid = ($faults | is-empty)
    let result = ($base | merge {
        complete: true, valid: $valid, faults: $faults, nonce: $stream.header.nonce,
        historical: $built.historical, deciding: ($valid and not $built.historical), build: $built.build, unchecked: $built.unchecked,
        contract: $contract, reading: (if $valid { guest-side $stream $contract.k } else { null }),
    })
    { result: $result, stream: $stream }
}

# A guest-only reading: its stream, receipts, binding, build, and guest
export def guest-reading [bytes: binary, identity: record, --eps: int = 10000, --test, --replay: path]: nothing -> record {
    (guest-of $bytes $identity $eps $test $replay).result
}
