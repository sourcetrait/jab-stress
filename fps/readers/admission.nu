# AdmissionMeasure's reading (FrameCeiling's PoolCore): each batch under
# `base` named in `labels`, its report's frames at schema 5 or 6, every
# run's. Refused before any verdict, every run named (PoolReaderStanding),
# unless every run is complete, valid, and seeded at one of SCHEMAS. Per
# batch: the runs and frames; the requests admitted, dropped at a full
# open ring, and filtered by the repeat filter; the frames dropping any
# and the most a frame dropped and admitted; the duplicates among the
# processed requests, each boundary's source batch's admitted less its
# unprocessed less its merged, read from the boundary's own tile record,
# the overlap across contexts among them; the unprocessed, whose
# duplicates stay unknown; the greatest open ring's fill and requesting
# surfaces. The verdict: TILE_RING and TILE_GUARANTEE stand at the
# census's provisional sizes only when no frame of any batch dropped a
# request. Written to `out` as nuon and printed; its own fixtures `nu
# admission.nu holds <base> <scratch>`.

# the schemas whose pool records the reading takes: 5, and 6, the same
# records beside a frame's harts record
const SCHEMAS = [5 6]

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

# Each batch's report under `base`, by label.
export def load [base: string, labels: list<string>]: nothing -> list<record> {
    $labels | each {|label| { label: $label, g: (open ($base | path join $label "gauge.nuon")) } }
}

# The runs not complete, valid, and seeded at one of SCHEMAS, each named.
export def standing-of [batches: list<record>]: nothing -> list<string> {
    $batches | each {|b| $b.g.runs | each {|r|
        let m = $r.measured
        if $m.complete and $m.valid and $m.seeded and $m.schema in $SCHEMAS { null } else {
            $"($b.label) run ($r.run): complete ($m.complete), valid ($m.valid), seeded ($m.seeded), schema ($m.schema)"
        }
    } | compact } | flatten
}

# The reading of loaded batches whose runs all stand.
export def reading-of [batches: list<record>]: nothing -> record {
    let read = ($batches | each {|b|
        let rows = ($b.g.rows | where {|r| ($r | get -o admitted) != null })
        let consumed = ($rows | where {|r| $r.batch_admitted > 0 })
        {
            label: $b.label, runs: ($b.g.runs | length), frames: ($rows | length),
            schemas: ($b.g.runs | get measured.schema | uniq),
            admitted: (total-of ($rows | get admitted)),
            dropped: (total-of ($rows | get dropped)),
            filtered: (total-of ($rows | get filtered)),
            dropping_frames: ($rows | where {|r| $r.dropped > 0 } | length),
            dropped_most: (most-of ($rows | get dropped)),
            admitted_most: (most-of ($rows | get admitted)),
            duplicates: (total-of ($consumed | each {|r| $r.batch_admitted - $r.unprocessed - $r.merged })),
            merged: (total-of ($rows | get merged)),
            unprocessed: (total-of ($rows | get unprocessed)),
            ring_fill_most: (most-of ($rows | get ring_fill)),
            requesting_most: (most-of ($rows | get requesting)),
        }
    })
    { batches: $read, ring_dropped: (total-of ($read | get dropped)), stands: ($read | all {|b| $b.dropped == 0 }) }
}

# The reading, or the refusal naming every run that does not stand.
export def read-or-refuse [batches: list<record>]: nothing -> record<refused: list<string>, reading: any> {
    let standing = (standing-of $batches)
    if not ($standing | is-empty) { return { refused: $standing, reading: null } }
    { refused: [], reading: (reading-of $batches) }
}

def main [base: path, out: path, ...labels: string] {
    let r = (read-or-refuse (load $base $labels))
    if not ($r.refused | is-empty) { error make { msg: $"admission refuses the reading: ($r.refused | str join '; ')" } }
    $r.reading | to nuon | save -f $out
    print ($r.reading.batches | select label runs frames admitted dropped filtered dropping_frames dropped_most duplicates unprocessed ring_fill_most requesting_most | table --width 200)
    print $"admission: TILE_RING and TILE_GUARANTEE (if $r.reading.stands { 'stand' } else { 'do not stand' }), ($r.reading.ring_dropped) requests dropped"
}

# The reader's own fixtures over AdmissionMeasure's saved batches under
# `base`, each refusal named and taken before the verdict, a case's failure
# raised with its name: the batches read whole as the positive control,
# the reading the saved `admission.nuon`'s; a run invalid, one incomplete,
# one unseeded, and one at schema 4, each refused; and one at schema 6
# read, the batch's schemas 5 and 6.
def "main holds" [base: string, scratch: string] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    mkdir $scratch
    let fail = {|name: string, why: string| error make { msg: $"admission holds: ($name): ($why)" } }
    let labels = [admission_factory_w2 admission_factory_w0 admission_settled_w2 admission_settled_w0]
    let batches = (load $base $labels)
    let whole = (read-or-refuse $batches)
    if not ($whole.refused | is-empty) { do $fail "the saved batches read whole" ($whole.refused | str join "; ") }
    let saved = (open ($base | path join "admission.nuon"))
    if $whole.reading != $saved { do $fail "the saved batches' reading unchanged" $"read ($whole.reading | to nuon | str substring 0..400)" }
    let measured = {|field: string, value: any| $batches | each {|b| if $b.label == "admission_settled_w0" { $b | update g ($b.g | update runs ($b.g.runs | each {|r| if $r.run == 2 { $r | update measured ($r.measured | update $field $value) } else { $r } })) } else { $b } } }
    let refuses = {|name: string, got: record, reason: string|
        if ($got.refused | is-empty) { do $fail $name "accepted" }
        if $got.reading != null { do $fail $name "read beside its refusal" }
        if not ($got.refused | any {|x| $x | str contains $reason }) { do $fail $name $"refused for ($got.refused | str join '; ')" }
    }
    do $refuses "an invalid run" (read-or-refuse (do $measured "valid" false)) "admission_settled_w0 run 2: complete true, valid false"
    do $refuses "an incomplete run" (read-or-refuse (do $measured "complete" false)) "admission_settled_w0 run 2: complete false"
    do $refuses "an unseeded run" (read-or-refuse (do $measured "seeded" false)) "seeded false"
    do $refuses "a run at schema 4" (read-or-refuse (do $measured "schema" 4)) "schema 4"
    let six = (read-or-refuse (do $measured "schema" 6))
    if not ($six.refused | is-empty) { do $fail "a run at schema 6" $"refused for ($six.refused | str join '; ')" }
    let schemas = ($six.reading.batches | where label == "admission_settled_w0" | first | get schemas | sort)
    if $schemas != [5 6] { do $fail "a run at schema 6" $"read at schemas ($schemas)" }
    print "admission holds: ok"
}
