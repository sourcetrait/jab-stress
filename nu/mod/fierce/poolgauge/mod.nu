# The fields a leg's frames are spread over, the tile time among them
const FIELDS = [draw_us critical_us planes_us walls_us raster_us tiles_us]

# An API record's bytes
const RECORD = 64

# A state record's kind in an API record
const KIND_STATE = 1

# The end marker's kind in an API record
const KIND_END = 9

# A console answer's kind in an API record
const KIND_CONSOLE = 11

# A storage record's kind in an API record
const KIND_STORAGE = 15

# The console's L as its answer carries it
const CONSOLE_L = 76

# The worst-tile probe's longest build's offset in a storage record
const PROBE_AT = 40

# The probe's first bucket's offset in a storage record
const PROBE_HIST_AT = 44

# The probe's buckets of whole builds
const PROBE_BUCKETS = 8

# rdtime's ticks a microsecond
const US_TICKS = 10

# The run resolver's bin, run in a nu of its own
const RESOLVER = path self ../../../bin/nuance/fierce/tilecensus/resolve.nu

# Least, median, 95th, and greatest by nearest rank, null-free
def spread [values: list<any>]: nothing -> record {
    let v = ($values | compact | sort)
    let n = ($v | length)
    if $n == 0 { return { n: 0, least: null, median: null, p95: null, most: null } }
    let rank = {|q: float| $v | get ((($q * $n) | math ceil) - 1) }
    { n: $n, least: ($v | first), median: (do $rank 0.5), p95: (do $rank 0.95), most: ($v | last) }
}

# A list's sum with its nulls dropped, 0 for an empty one
def total-of [values: list<any>]: nothing -> any {
    let v = ($values | compact)
    if ($v | is-empty) { 0 } else { $v | math sum }
}

# A list's greatest with its nulls dropped, null for an empty one
def most-of [values: list<any>]: nothing -> any {
    let v = ($values | compact)
    if ($v | is-empty) { null } else { $v | math max }
}

# Buckets summed across a list of histograms
def hist-sum [hists: list<any>]: nothing -> list<int> {
    0..<$PROBE_BUCKETS | each {|k| total-of ($hists | each {|h| $h | get $k }) }
}

# Each requested run's capture or its refusal, resolved in a nu of its own
def resolve-runs [requests: list<record<report: string, run: int>>]: nothing -> list<record> {
    if ($requests | is-empty) { return [] }
    let r = (^nu $RESOLVER ($requests | to nuon) | complete)
    if $r.exit_code != 0 { error make { msg: $"the run resolver failed: ($r.stderr)" } }
    $r.stdout | from nuon
}

# A capture read to its first end marker: L answers, the probe's builds
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

# Each batch's gauge report under `base`, by label
export def load [base: string, labels: list<string>]: nothing -> list<record> {
    $labels | each {|label|
        let report = ($base | path join $label "gauge.nuon")
        { label: $label, report: $report, g: (open $report) }
    }
}

# Each run not complete, valid, and seeded, named
export def standing-of [batches: list<record>]: nothing -> list<string> {
    $batches | each {|b| $b.g.runs | each {|r|
        let m = $r.measured
        if $m.complete and $m.valid and $m.seeded { null } else { $"($b.label) run ($r.run): complete ($m.complete), valid ($m.valid), seeded ($m.seeded)" }
    } | compact } | flatten
}

# Every run's capture read from its bound directory, and the runs refused
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

# Whether a row is settled, by pool-holds' predicate from schema 5
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

# A leg's frames as the mode reads them, cold and steady, or its refusal
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

# A run's cold as a whole: drawing and critical path summed, its frames
def whole-of [cold: list<any>]: nothing -> record {
    if ($cold | is-empty) { return { draw_us: null, critical_us: null, frames: 0 } }
    { draw_us: (total-of ($cold | get draw_us)), critical_us: (total-of ($cold | get critical_us)), frames: ($cold | length) }
}

# The identity's parts a comparison holds alike, the image apart
def held-alike [id: record]: nothing -> record {
    {
        kernel: ($id | get -o build.kernel_sha256), assets: ($id | get -o assets.digest),
        route: ($id | get -o route.sha256), toolchain: ($id | get -o toolchain.assembler),
        cadence: ($id | get -o mode.cadence), machine: ($id | get -o machine),
    }
}

# A set of frames summarised: counts, builds, and each field's spread
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

# PoolCore's reading of loaded batches and their captures
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

# The reading of the batches under `base`, or the refusal naming why
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

# PoolCore's reading saved to `out` and summarised, or refused
export def main [mode: string, base: string, out: string, ...labels: string] {
    let r = (read-or-refuse $mode $base $labels)
    if not ($r.refused | is-empty) { error make { msg: $"poolgauge refuses the reading: ($r.refused | str join '; ')" } }
    $r.doc | to nuon --indent 1 | save --raw -f $out
    print $"poolgauge ($mode): ($labels | length) batches, identities alike ($r.doc.identities_alike); ($out)"
}
