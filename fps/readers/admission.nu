# AdmissionMeasure's reading (FrameCeiling's PoolCore): each batch under
# `base` named in `labels`, its report's frames at schema 5, 6, or 7, every
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
# request. Written to `out` as nuon and printed.

# the schemas whose pool records the reading takes: 5, and 6 and 7, the
# same records beside a frame's harts record and, at 7, its receipt
const SCHEMAS = [5 6 7]

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
