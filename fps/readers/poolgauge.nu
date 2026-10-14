# PoolCore's measurements (FrameCeiling.md's PoolMeasure): the batteries'
# gauge.nuon files under one base directory, a batch a label, a build a
# label less its trailing _<n>. Refused before anything is summarized,
# every reason named (PoolReaderStanding): a run not complete, valid, and
# seeded; a run no identity file binds by SHA-256, or whose identity's
# seed is not its own, resolved in a nu of its own as TileCensus's runs
# are (tilecensus_resolve.nu); a bound directory holding no capture, or a
# capture holding no end marker; and in `settled` a view leg without
# exactly one L, or not settled after it. Each run's capture is read from
# its bound directory up to its first end marker, past which the game
# goes on and nothing is read: the console's L answers, each the frame of
# the state records before it, and the worst-tile probe's words where a
# candidate keeps them.
#
# `settled` reads each view leg apart (SettledWindow). Its L is the
# console's answer to it, an answer between state records F - 1 and F
# governing frame F (main.S's frame loop: frame_records, console_read,
# world_draw, state_report). A frame is settled from schema 5 with no block
# drawn without its tile, no BUILDING tile, and nothing admitted, dropped,
# filtered, or built (pool-holds' predicate), and below 5 with no cell
# built, the only settling field its records carry. The cold is the
# frames from the L to the first settled frame at or after it, the steady
# every frame from there to the leg's end, each one settled. The frames
# between a placement and its L, the placement's own building among them,
# are read in neither. `play` reads every frame of each leg as steady.
#
# Per batch and leg the least, median, 95th, and greatest of the drawing,
# the critical path, the planes, the walls, the raster, and the tile time
# (the pool's boundary from schema 5, the atlas build's construction inside
# its planes and walls below it, so never set beside the other), with the
# frames read, the tiles built, the frames building, and from schema 5 the
# construction's spread and the frames past the allowance; settled, the
# cold's whole, each run's drawing and critical path summed from the L to
# settling and its frames, spread over the batch's runs, and each leg's L
# and settling frame; per build the mean of its batches' medians with half
# their range and the difference from the first build named; and where a
# run's capture carries the worst-tile probe (a candidate's storage
# record: at offset 40 the frame's longest whole tile build in rdtime's
# ticks, at 44 to 59 the frame's whole builds in eight u16 buckets, under
# 6.4 us and then each a power of two wider, the last 409.6 us and over,
# the schema at 60 after them), the longest whole build in microseconds and
# the builds by bucket, summed over the runs and over the batches, a probe
# keeping no buckets reading zeros. Run under the real nu from a scratch
# justfile: `nu poolgauge.nu <settled|play> <base> <out.nuon> <label>...`;
# its own fixtures `nu poolgauge.nu holds <gauge> <scratch>`.

const FIELDS = [draw_us critical_us planes_us walls_us raster_us tiles_us]
const RECORD = 64
const KIND_STATE = 1
const KIND_END = 9
const KIND_CONSOLE = 11
const KIND_STORAGE = 15
const CONSOLE_L = 76
const PROBE_AT = 40
const PROBE_HIST_AT = 44
const PROBE_BUCKETS = 8
const US_TICKS = 10
const RESOLVER = (path self | path dirname | path join "tilecensus_resolve.nu")

def spread [values: list<any>]: nothing -> record {
    let v = ($values | compact | sort)
    let n = ($v | length)
    if $n == 0 { return { n: 0, least: null, median: null, p95: null, most: null } }
    let rank = {|q: float| $v | get ((($q * $n) | math ceil) - 1) }
    { n: $n, least: ($v | first), median: (do $rank 0.5), p95: (do $rank 0.95), most: ($v | last) }
}

# A list's sum and greatest, its nulls dropped: 0 and null for an empty
# one, which math's own refuse.
def total-of [values: list<any>]: nothing -> any {
    let v = ($values | compact)
    if ($v | is-empty) { 0 } else { $v | math sum }
}

def most-of [values: list<any>]: nothing -> any {
    let v = ($values | compact)
    if ($v | is-empty) { null } else { $v | math max }
}

# Buckets summed across a list of histograms.
def hist-sum [hists: list<any>]: nothing -> list<int> {
    0..<$PROBE_BUCKETS | each {|k| total-of ($hists | each {|h| $h | get $k }) }
}

# Where each requested run's capture is, or why it is refused, each
# request a report and a run number in it, resolved in a nu of its own
# (tilecensus_resolve.nu): the capture complete and valid, the directory
# the one whose identity file binds by SHA-256, the identity's seed the
# run's.
def resolve-runs [requests: list<record<report: string, run: int>>]: nothing -> list<record> {
    if ($requests | is-empty) { return [] }
    let r = (^nu $RESOLVER ($requests | to nuon) | complete)
    if $r.exit_code != 0 { error make { msg: $"the run resolver failed: ($r.stderr)" } }
    $r.stdout | from nuon
}

# A capture read in order to its first end marker: the console's L
# answers, each the frame of the state records before it; the probe's
# longest whole build in ticks and its whole builds by bucket, over the
# storage records; and whether the marker came.
export def capture-of [api: path]: nothing -> record<lifts: list<int>, worst: int, hist: list<int>, ended: bool> {
    let b = (open --raw $api | into binary)
    mut states = 0
    mut lifts = []
    mut worst = 0
    mut hist = (0..<$PROBE_BUCKETS | each { 0 })
    mut ended = false
    for c in ($b | chunks $RECORD) {
        if ($c | bytes length) != $RECORD { break }
        let kind = ($c | bytes at 0..<4 | into int --endian little)
        if $kind == $KIND_END {
            $ended = true
            break
        }
        if $kind == $KIND_STATE {
            $states += 1
        } else if $kind == $KIND_CONSOLE {
            if ($c | bytes at 4..<8 | into int --endian little) == $CONSOLE_L { $lifts = ($lifts | append $states) }
        } else if $kind == $KIND_STORAGE {
            let w = ($c | bytes at $PROBE_AT..<($PROBE_AT + 4) | into int --endian little)
            if $w > $worst { $worst = $w }
            $hist = ($hist | enumerate | each {|e|
                let at = ($PROBE_HIST_AT + 2 * $e.index)
                $e.item + ($c | bytes at $at..<($at + 2) | into int --endian little)
            })
        }
    }
    { lifts: $lifts, worst: $worst, hist: $hist, ended: $ended }
}

# Each batch's report under `base`, by label.
export def load [base: string, labels: list<string>]: nothing -> list<record> {
    $labels | each {|label|
        let report = ($base | path join $label "gauge.nuon")
        { label: $label, report: $report, g: (open $report) }
    }
}

# The runs not complete, valid, and seeded, each named.
export def standing-of [batches: list<record>]: nothing -> list<string> {
    $batches | each {|b| $b.g.runs | each {|r|
        let m = $r.measured
        if $m.complete and $m.valid and $m.seeded { null } else { $"($b.label) run ($r.run): complete ($m.complete), valid ($m.valid), seeded ($m.seeded)" }
    } | compact } | flatten
}

# Every run's capture read from its bound directory, and the runs
# refused, each named with its reasons: unbound, no capture there, or no
# end marker in it.
export def facts-of [batches: list<record>]: nothing -> record<facts: list<record>, refused: list<string>> {
    let requests = ($batches | each {|b| $b.g.runs | each {|r| { report: $b.report, run: $r.run } } } | flatten)
    let answers = (resolve-runs $requests)
    let read = ($answers | each {|a|
        let label = ($batches | where report == $a.report | first | get label)
        if not ($a.refused | is-empty) { return { label: $label, run: $a.run, refused: $a.refused } }
        let api = ($a.dir | path join "api.out")
        if not ($api | path exists) { return { label: $label, run: $a.run, refused: [$"no capture in ($a.dir)"] } }
        let c = (capture-of $api)
        if not $c.ended { return { label: $label, run: $a.run, refused: ["its capture holds no end marker"] } }
        { label: $label, run: $a.run, refused: [] } | merge $c
    })
    let refused = ($read | where {|x| not ($x.refused | is-empty) } | each {|x| $"($x.label) run ($x.run): ($x.refused | str join '; ')" })
    { facts: ($read | where {|x| $x.refused | is-empty }), refused: $refused }
}

# Whether a row is settled: from schema 5 pool-holds' predicate, below it no
# cell built.
def settled-row [r: record, schema: int]: nothing -> bool {
    if $schema >= 5 {
        [
            ($r.missed_blocks == 0)
            ($r.building == 0)
            ($r.admitted == 0)
            ($r.dropped == 0)
            ($r.filtered == 0)
            ($r.tiles_built == 0)
        ] | all {|x| $x }
    } else {
        ($r.tiles_built | default 0) == 0
    }
}

# A leg's frames as the mode reads them, with why it is refused, null when
# it is not: in play every frame as steady; settled, its one L, the cold
# from it to the first settled frame at or after it, and the steady every
# frame from there to the leg's end, each one settled.
def frames-of [mode: string, rows: list<any>, lifts: list<int>, schema: int]: nothing -> record {
    let none = { refused: null, lift: null, settled_at: null, cold: [], steady: [] }
    if $mode == "play" { return ($none | merge { steady: $rows }) }
    let first = ($rows | first | get frame)
    let last = ($rows | last | get frame)
    let mine = ($lifts | where {|f| $f >= $first and $f <= $last })
    if ($mine | is-empty) { return ($none | merge { refused: "no L answered" }) }
    if ($mine | length) > 1 { return ($none | merge { refused: $"($mine | length) L answers, at frames ($mine | str join ', ')" }) }
    let lift = ($mine | first)
    let after = ($rows | where {|r| $r.frame >= $lift })
    let at = ($after | enumerate | where {|e| settled-row $e.item $schema } | get -o 0.index)
    if $at == null { return ($none | merge { refused: $"never settled after its L at frame ($lift)" }) }
    let steady = ($after | skip $at)
    let unsettled = ($steady | where {|r| not (settled-row $r $schema) })
    if not ($unsettled | is-empty) {
        return ($none | merge { refused: $"($unsettled | length) frames unsettled after settling at frame ($steady | first | get frame), the first ($unsettled | first | get frame)" })
    }
    { refused: null, lift: $lift, settled_at: ($steady | first | get frame), cold: ($after | first $at), steady: $steady }
}

# A run's cold as a whole: its drawing and critical path summed from the
# L to settling, and its frames.
def whole-of [cold: list<any>]: nothing -> record {
    if ($cold | is-empty) { return { draw_us: null, critical_us: null, frames: 0 } }
    { draw_us: (total-of ($cold | get draw_us)), critical_us: (total-of ($cold | get critical_us)), frames: ($cold | length) }
}

def held-alike [id: record]: nothing -> record {
    {
        kernel: ($id | get -o build.kernel_sha256), assets: ($id | get -o assets.digest),
        route: ($id | get -o route.sha256), toolchain: ($id | get -o toolchain.assembler),
        cadence: ($id | get -o mode.cadence), machine: ($id | get -o machine),
    }
}

def summary [frames: list<any>]: nothing -> record {
    let base = {
        frames: ($frames | length),
        tiles_built: (total-of ($frames | each {|x| $x.tiles_built | default 0 })),
        building_frames: ($frames | where {|x| ($x.tiles_built | default 0) > 0 } | length),
        build_us: (spread ($frames | each {|x| $x | get -o build_us })),
        overrun_frames: ($frames | where {|x| ($x | get -o overrun_us | default 0) > 0 } | length),
    }
    $FIELDS | reduce --fold $base {|f, acc| $acc | insert $f (spread ($frames | each {|x| $x | get -o $f })) }
}

# The reading of loaded batches and their runs' captures (facts-of): per
# batch and leg, per build, the differences from the first build named,
# and the legs refused, each named.
export def analyse [mode: string, batches: list<record>, facts: list<record>]: nothing -> record {
    if $mode not-in [settled play] { error make { msg: $"the mode is settled or play, not ($mode)" } }
    let read = ($batches | each {|b|
        let runs = ($b.g.runs | each {|r|
            let rows = ($b.g.rows | where run == $r.run)
            let fact = ($facts | where {|x| $x.label == $b.label and $x.run == $r.run } | get -o 0)
            let lifts = (if $fact == null { [] } else { $fact.lifts })
            let worst = (if $fact == null or $fact.worst == 0 { null } else { $fact.worst / $US_TICKS })
            let hist = (if $fact == null { 0..<$PROBE_BUCKETS | each { 0 } } else { $fact.hist })
            let schema = $r.measured.schema
            {
                run: $r.run, schema: $schema, probe_us: $worst, probe_hist: $hist,
                legs: ($rows | get leg | uniq | where {|leg| $mode == "play" or $leg != "start" } | each {|leg|
                    let f = (frames-of $mode ($rows | where leg == $leg) $lifts $schema)
                    { leg: $leg, refused: $f.refused, lift: $f.lift, settled_at: $f.settled_at, cold: $f.cold, steady: $f.steady, whole: (whole-of $f.cold) }
                }),
            }
        })
        { label: $b.label, build: ($b.label | str replace --regex '_\d+$' ''), image: ($b.g.identity | get -o build.image_sha256), alike: (held-alike $b.g.identity), runs: $runs }
    })
    let problems = ($read | each {|b| $b.runs | each {|r| $r.legs | where {|l| $l.refused != null } | each {|l| $"($b.label) run ($r.run) ($l.leg): ($l.refused)" } } | flatten } | flatten)
    let legs = ($read | get runs | flatten | get legs | flatten | get leg | uniq)
    let per_batch = ($read | each {|b|
        {
            label: $b.label, build: $b.build, schemas: ($b.runs | get schema | uniq),
            probe_us: (most-of ($b.runs | get probe_us)), probe_runs_us: ($b.runs | get probe_us),
            probe_hist: (hist-sum ($b.runs | get probe_hist)),
            settling: ($b.runs | each {|r| $r.legs | each {|l| { run: $r.run, leg: $l.leg, lift: $l.lift, settled_at: $l.settled_at } } } | flatten),
            legs: ($legs | each {|leg|
                let these = ($b.runs | each {|r| $r.legs | where leg == $leg | get -o 0 } | compact)
                {
                    leg: $leg, cold: (summary ($these | get cold | flatten)), steady: (summary ($these | get steady | flatten)),
                    whole: { draw_us: (spread ($these | get whole.draw_us)), critical_us: (spread ($these | get whole.critical_us)), frames: (spread ($these | get whole.frames)) },
                }
            }),
        }
    })
    let parts = [
        { part: cold, fields: ($FIELDS | append [frames tiles_built]) }
        { part: steady, fields: ($FIELDS | append [frames tiles_built]) }
        { part: whole, fields: [draw_us critical_us frames] }
    ]
    let builds = ($read | get build | uniq)
    let per_build = ($builds | each {|bd|
        let these = ($per_batch | where build == $bd)
        {
            build: $bd, batches: ($these | get label), probe_us: (most-of ($these | get probe_us)),
            probe_hist: (hist-sum ($these | get probe_hist)),
            legs: ($legs | each {|leg|
                { leg: $leg } | merge ($parts | reduce --fold {} {|p, acc|
                    $acc | insert $p.part ($p.fields | reduce --fold {} {|f, acc2|
                        let medians = ($these | each {|t| let s = ($t.legs | where leg == $leg | get 0 | get $p.part | get $f); if ($s | describe) =~ '^record' { $s.median } else { $s } } | compact)
                        $acc2 | insert $f (if ($medians | length) != ($these | length) or ($medians | is-empty) { null } else {
                            { mean: ($medians | math avg), half: ((($medians | math max) - ($medians | math min)) / 2) }
                        })
                    })
                })
            }),
        }
    })
    let first = ($per_build | first)
    let differences = ($per_build | skip 1 | each {|b|
        {
            build: $b.build, from: $first.build,
            legs: ($legs | each {|leg|
                let mine = ($b.legs | where leg == $leg | get 0)
                let theirs = ($first.legs | where leg == $leg | get 0)
                { leg: $leg } | merge ([cold steady whole] | reduce --fold {} {|part, acc|
                    $acc | insert $part ([draw_us critical_us] | reduce --fold {} {|f, acc2|
                        let x = ($mine | get $part | get $f)
                        let y = ($theirs | get $part | get $f)
                        $acc2 | insert $f (if $x == null or $y == null { null } else { $x.mean - $y.mean })
                    })
                })
            }),
        }
    })
    {
        mode: $mode, problems: $problems, identities_alike: (($read | get alike | uniq | length) == 1),
        images: ($read | each {|b| { label: $b.label, image: $b.image } }),
        batches: $per_batch, builds: $per_build, differences: $differences,
    }
}

# The reading of the batches under `base`, or the refusal naming every
# reason: the runs' standing first, then their binding and captures, then
# the legs.
export def read-or-refuse [mode: string, base: string, labels: list<string>]: nothing -> record<refused: list<string>, doc: any> {
    let batches = (load $base $labels)
    let standing = (standing-of $batches)
    if not ($standing | is-empty) { return { refused: $standing, doc: null } }
    let bound = (facts-of $batches)
    if not ($bound.refused | is-empty) { return { refused: $bound.refused, doc: null } }
    let doc = (analyse $mode $batches $bound.facts)
    if not ($doc.problems | is-empty) { return { refused: $doc.problems, doc: null } }
    { refused: [], doc: $doc }
}

def main [mode: string, base: string, out: string, ...labels: string] {
    let r = (read-or-refuse $mode $base $labels)
    if not ($r.refused | is-empty) { error make { msg: $"poolgauge refuses the reading: ($r.refused | str join '; ')" } }
    $r.doc | to nuon --indent 1 | save --raw -f $out
    print $"poolgauge ($mode): ($labels | length) batches, identities alike ($r.doc.identities_alike); ($out)"
}

# The reader's own fixtures over the saved batteries under `gauge` and
# altered copies under `scratch`, each refusal named with its reason and
# taken before anything is summarized, every case's work run under its
# name so a raise fails it by name, the in-memory cases first and the
# positive controls last: a run invalid, one incomplete, and one unseeded
# refused, a run whose identity hash is mismatched refused unbound, and a
# capture cut before its end marker refused (PoolReaderStanding); a
# storage record of conspicuous probe words appended past a capture's end
# marker, the capture accepted and its reading unchanged; a pool leg's
# steady frame holding a BUILDING tile, an eligible miss, an admission, a
# drop, a filtered request, or a tile built, each refusing the leg, and a
# leg with no L and one with two each refused (SettledWindow); and the
# settled comparison (poolmeasure_settled_2) and the probes
# (poolmeasure_probehist_2) read whole, their numbers the saved readings'.
def "main holds" [gauge: string, scratch: string] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    mkdir $scratch
    let fail = {|name: string, why: string| error make { msg: $"poolgauge holds: ($name): ($why)" } }
    let named = {|name: string, work: closure| try { do $work } catch {|e| do $fail $name $"raised: ($e.msg | str substring 0..300)" } }
    let same = {|name: string, got: any, want: any| if $got != $want { do $fail $name $"read ($got | to nuon | str substring 0..300), saved ($want | to nuon | str substring 0..300)" } }
    let refuses = {|name: string, got: list<string>, reason: string|
        if ($got | is-empty) { do $fail $name "accepted" }
        if not ($got | any {|x| $x | str contains $reason }) { do $fail $name $"refused for ($got | str join '; ')" }
    }
    let settled_base = ($gauge | path join "poolmeasure_settled_2")
    let probe_base = ($gauge | path join "poolmeasure_probehist_2")
    # a copy of a batch under `scratch`, its report and each run's identity
    # and capture, its runs resolved beside the copy's report
    let copy = {|case: string, base: string, label: string|
        let source = ($base | path join $label)
        let dir = ($scratch | path join $case $label)
        mkdir $dir
        cp ($source | path join "gauge.nuon") $dir
        for n in [1 2 3] {
            let d = ($dir | path join $"run_($n)")
            mkdir $d
            for f in ["identity.nuon" "api.out"] { cp ($source | path join $"run_($n)" $f) ($d | path join $f) }
        }
        ($scratch | path join $case)
    }

    # PoolReaderStanding: the runs' standing, binding, and capture, each
    # refusal before any summary
    let batches = (load $settled_base [pool_1])
    let measured = {|field: string, value: bool| $batches | each {|b| $b | update g ($b.g | update runs ($b.g.runs | each {|r| if $r.run == 1 { $r | update measured ($r.measured | update $field $value) } else { $r } })) } }
    do $refuses "an invalid run" (do $named "an invalid run" { standing-of (do $measured "valid" false) }) "pool_1 run 1: complete true, valid false"
    do $refuses "an incomplete run" (do $named "an incomplete run" { standing-of (do $measured "complete" false) }) "pool_1 run 1: complete false"
    do $refuses "an unseeded run" (do $named "an unseeded run" { standing-of (do $measured "seeded" false) }) "seeded false"
    let unbound_dir = ($scratch | path join "unbound" "pool_1")
    mkdir $unbound_dir
    let g1 = ($batches | first | get g)
    $g1 | update runs ($g1.runs | each {|r| if $r.run == 2 { $r | update identity_sha256 (0..<64 | each { "0" } | str join) } else { $r } }) | to nuon | save ($unbound_dir | path join "gauge.nuon")
    do $refuses "a run whose identity hash is mismatched" (do $named "a run whose identity hash is mismatched" { facts-of (load ($scratch | path join "unbound") [pool_1]) | get refused }) "pool_1 run 2: no identity file binds"
    let cut = (do $copy "cut" $probe_base "probe64_1")
    let cut_api = ($cut | path join "probe64_1" "run_2" "api.out")
    let cut_bytes = (open --raw $cut_api | into binary)
    mut cut_at = 0
    for c in ($cut_bytes | chunks $RECORD) {
        if ($c | bytes at 0..<4 | into int --endian little) == $KIND_END { break }
        $cut_at += $RECORD
    }
    $cut_bytes | bytes at 0..<$cut_at | save --raw -f $cut_api
    do $refuses "a capture cut before its end marker" (do $named "a capture cut before its end marker" { facts-of (load $cut [probe64_1]) | get refused }) "probe64_1 run 2: its capture holds no end marker"

    # the end marker bounds the capture: a storage record appended past it,
    # its probe words conspicuous, leaves the capture accepted and its
    # reading unchanged
    let ended = (do $copy "ended" $probe_base "probe32_1")
    let loud = ([(15 | into binary --endian little | bytes at 0..<4) (0..<36 | each { 0x[00] } | bytes collect) (16777215 | into binary --endian little | bytes at 0..<4) (0..<8 | each { 999 | into binary --endian little | bytes at 0..<2 } | bytes collect) (5 | into binary --endian little | bytes at 0..<4)] | bytes collect)
    let api1 = ($ended | path join "probe32_1" "run_1" "api.out")
    [(open --raw $api1 | into binary) $loud] | bytes collect | save --raw -f $api1
    let theirs = (do $named "the probe batch read whole" { read-or-refuse "settled" $probe_base [probe32_1] })
    let mine = (do $named "a record past the end marker leaves the capture accepted" { read-or-refuse "settled" $ended [probe32_1] })
    if not ($mine.refused | is-empty) { do $fail "a record past the end marker leaves the capture accepted" ($mine.refused | str join "; ") }
    do $same "a record past the end marker leaves the builds by bucket unchanged" ($mine.doc.batches | first | get probe_hist) ($theirs.doc.batches | first | get probe_hist)
    do $same "a record past the end marker leaves the longest build unchanged" ($mine.doc.batches | first | get probe_runs_us) ($theirs.doc.batches | first | get probe_runs_us)

    # SettledWindow: a pool leg's steady frame unsettled, or its L missing
    # or doubled, refuses the leg
    let bound = (do $named "the pool batch's captures read" { facts-of $batches })
    let leg = "yard"
    let rows1 = ($batches | first | get g.rows | where run == 1 and leg == $leg)
    let fact1 = ($bound.facts | where run == 1 | first)
    let lift = ($fact1.lifts | where {|f| $f >= ($rows1 | first | get frame) and $f <= ($rows1 | last | get frame) } | first)
    let probe_frame = ($rows1 | last | get frame) - 100
    let altered = {|field: string| $batches | each {|b| $b | update g ($b.g | update rows ($b.g.rows | each {|row| if $row.run == 1 and $row.frame == $probe_frame { $row | update $field 1 } else { $row } })) } }
    let refuses_leg = {|name: string, doc: record, reason: string|
        let mine = ($doc.problems | where {|p| $p starts-with $"pool_1 run 1 ($leg): " })
        if ($mine | is-empty) { do $fail $name "accepted" }
        if not ($mine | any {|p| $p | str contains $reason }) { do $fail $name $"refused for ($mine | str join '; ')" }
    }
    for field in [building missed_blocks admitted dropped filtered tiles_built] {
        let name = $"a steady frame with ($field) refuses its leg"
        do $refuses_leg $name (do $named $name { analyse "settled" (do $altered $field) $bound.facts }) $"the first ($probe_frame)"
    }
    let relifted = {|lifts: list<int>| $bound.facts | each {|x| if $x.run == 1 { $x | update lifts $lifts } else { $x } } }
    do $refuses_leg "a leg with no L" (do $named "a leg with no L" { analyse "settled" $batches (do $relifted ($fact1.lifts | where {|f| $f != $lift })) }) "no L answered"
    do $refuses_leg "a leg with two L answers" (do $named "a leg with two L answers" { analyse "settled" $batches (do $relifted ($fact1.lifts | append ($lift + 5) | sort)) }) "2 L answers"

    # the positive controls: each battery read whole, its numbers the
    # saved reading's
    let settled = (do $named "the settled comparison read whole" { read-or-refuse "settled" $settled_base [base_1 pool_1 pool_2 base_2] })
    if not ($settled.refused | is-empty) { do $fail "the settled comparison read whole" ($settled.refused | str join "; ") }
    let saved_settled = (open ($settled_base | path join "poolgauge_settled.nuon"))
    for b in $settled.doc.builds {
        let s = ($saved_settled.builds | where build == $b.build | first)
        for l in $b.legs {
            let t = ($s.legs | where leg == $l.leg | first)
            do $same $"the settled comparison's ($b.build) ($l.leg) steady drawing" $l.steady.draw_us $t.steady.draw_us
            do $same $"the settled comparison's ($b.build) ($l.leg) steady critical path" $l.steady.critical_us $t.steady.critical_us
            do $same $"the settled comparison's ($b.build) ($l.leg) cold whole" $l.whole.draw_us $t.whole.draw_us
        }
    }
    let probes = (do $named "the probes read whole" { read-or-refuse "settled" $probe_base [probe32_1 probe64_1 probe64_2 probe32_2] })
    if not ($probes.refused | is-empty) { do $fail "the probes read whole" ($probes.refused | str join "; ") }
    let saved_probes = (open ($probe_base | path join "poolgauge_probes.nuon"))
    for b in $probes.doc.builds {
        let s = ($saved_probes.builds | where build == $b.build | first)
        do $same $"the probes' ($b.build) builds by bucket" $b.probe_hist $s.probe_hist
        do $same $"the probes' ($b.build) longest build" $b.probe_us $s.probe_us
    }
    print "poolgauge holds: ok"
}
