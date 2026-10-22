use (path self ../../../../../jab/kit/fierce/nu/mod/census)

# The run resolver's bin, run in a nu of its own
const RESOLVER = path self ../../../bin/nuance/fierce/tilecensus/resolve.nu

# The tile sides the census reads
const SIDES = [32 64 128]

# The guarantees the open ring's fill is read past
const GUARANTEES = [0 1 2 4 8 16 32 64]

# The pool sizes in MiB whose slots are counted at each side
const POOLS_MIB = [16 32]

# A texel's bytes
const TEXEL_BYTES = 4

# The short working set's window in frames
const SHORT = 30

# The long working set's window in frames
const WINDOW = 120

# A side record's fields the summary spreads
const SIDE_FIELDS = [eligible straddling outside demand planes walls openings sampled uniform surfaces]

# The side whose mapped pixels are held to the rows' lit pixels
const BOUND_SIDE = 32

# Least, median, 95th, 99th, and greatest by nearest rank, nulls dropped
def spread [values: list<any>]: nothing -> record {
    let v = ($values | compact | sort)
    let n = ($v | length)
    if $n == 0 { return { n: 0, least: null, median: null, p95: null, p99: null, most: null } }
    let rank = {|q: float| $v | get ((($q * $n) | math ceil) - 1) }
    { n: $n, least: ($v | first), median: (do $rank 0.5), p95: (do $rank 0.95), p99: (do $rank 0.99), most: ($v | last) }
}

# A part's share of a whole, null for a zero whole
def ratio [part: int, whole: int]: nothing -> any {
    if $whole == 0 { null } else { $part / $whole }
}

# A sum that reads an empty list as 0
def sum-of [values: list<any>]: nothing -> number {
    if ($values | is-empty) { 0 } else { $values | math sum }
}

# The open ring's fill past each guarantee
def fills-of [counts: list<int>]: nothing -> list<int> {
    $GUARANTEES | each {|g| sum-of ($counts | each {|n| if $n > $g { $n - $g } else { 0 } }) }
}

# A context's list folded to its counts and fills, all and walls alone
def context-of [c: record, below: oneof<int, nothing>]: nothing -> record {
    let counts = ($c.pairs | get count)
    let walls = (if $below == null { [] } else { $c.pairs | where surface >= $below | get count })
    {
        context: $c.context, requests: $c.requests, distinct: $c.distinct, listed: $c.listed, counts: $counts,
        fills: (fills-of $counts),
        wall_counts: $walls, wall_distinct: (sum-of $walls), wall_listed: ($walls | length), wall_fills: (fills-of $walls),
    }
}

# Each requested run's census or its refusal, resolved in a nu of its own
export def resolve-runs [requests: list<record<report: string, run: int>>]: nothing -> list<record> {
    let r = (^nu $RESOLVER ($requests | to nuon) | complete)
    if $r.exit_code != 0 { error make { msg: $"the run resolver failed: ($r.stderr)" } }
    $r.stdout | from nuon
}

# A resolved run's census: frames marked, windows, and problems
export def census-of [dir: string, g: record, r: record]: nothing -> record {
    let serial = (open --raw ($dir | path join "serial.log") | decode)
    let rows = ($g.rows | where run == $r.run | sort-by frame)
    let numbers = ($rows | get frame)
    let last = ($numbers | last)
    let ordered = ($numbers == (0..$last | each {|i| $i }))
    let by_frame = ($rows | reduce --fold {} {|row, acc| $acc | upsert ($row.frame | into string) { leg: $row.leg, lit: $row.lit_pixels } })
    let directory = (census directory $serial)
    let edge = (census edge $serial)
    let all = (census frames $serial)
    let unparsed = ($all | where frame == null | length)
    let parsed = ($all | where frame != null)
    let inside = ($parsed | where frame <= $last)
    mut streak = 0
    mut previous = -1
    mut flags = []
    mut gaps = []
    for f in ($inside | each {|f| { frame: $f.frame, valid: $f.valid } }) {
        if $f.frame != $previous + 1 { $gaps = ($gaps | append { after: $previous, at: $f.frame }) }
        $streak = (if not $f.valid { 0 } else if $f.frame == $previous + 1 { $streak + 1 } else { 1 })
        $previous = $f.frame
        $flags = ($flags | append { short: ($streak >= $SHORT), long: ($streak >= $WINDOW) })
    }
    let marked = ($inside | zip $flags | each {|z|
        let f = $z.0
        {
            frame: $f.frame, leg: ($by_frame | get -o ($f.frame | into string) | get -o leg), valid: $f.valid, lighting: $f.lighting,
            short: $z.1.short, long: $z.1.long, sides: $f.sides,
        }
    })
    let over = ($inside | each {|f|
        let s = ($f.sides | where side == $BOUND_SIDE | get -o 0)
        let l = ($by_frame | get -o ($f.frame | into string) | get -o lit)
        if $s == null or $l == null { null } else {
            let mapped = ($s.eligible_pixels + $s.straddling_pixels)
            if $mapped > $l { { frame: $f.frame, mapped: $mapped, lit: $l } } else { null }
        }
    } | compact)
    let invalid = ($inside | where {|f| not $f.valid } | each {|f| { frame: $f.frame, reasons: $f.reasons } })
    let mismatches = (sum-of ($inside | each {|f| sum-of ($f.sides | get mismatches) }))
    let lightings = ($inside | get lighting | uniq)
    let missing = (($last + 1) - ($inside | get frame | uniq | length))
    let problems = ([
        (if $ordered { null } else { "the rows are not every frame from 0 in order" }),
        (if $directory == null { "the log holds no census directory" } else { null }),
        (if $edge == null { "no census edge line" } else if $edge.skipped { "the census edge skipped" } else if $edge.nodes != 0 or $edge.sampler != 0 { $"the census edge read nodes ($edge.nodes), sampler ($edge.sampler)" } else { null }),
        (if $unparsed > 0 { $"($unparsed) census frames whose frame line does not parse" } else { null }),
        (if ($gaps | is-empty) { null } else { $"gaps in the census frames: ($gaps | to nuon)" }),
        (if $missing > 0 { $"($missing) measured frames with no census" } else { null }),
        (if ($invalid | is-empty) { null } else { $"($invalid | length) measured census frames invalid, the first ($invalid | first | to nuon)" }),
        (if $mismatches > 0 { $"($mismatches) uniform verdicts the sampler refused" } else { null }),
        (if ($lightings | length) > 1 { $"lighting revisions ($lightings | str join ', ') inside the measurement" } else { null }),
    ] | compact)
    {
        last: $last, census_frames: ($all | length), measured: ($inside | length), outside: (($parsed | length) - ($inside | length)),
        invalid: ($invalid | length), cut: ($all | where {|f| not $f.ended } | get frame),
        directory: $directory, edge: $edge, lighting: $lightings, problems: $problems, over: $over, frames: $marked,
    }
}

# One run of a batch under its resolution, refused or its census read
def run-of [g: record, r: record, resolved: record]: nothing -> record {
    let base = { run: $r.run, seed: $r.seed, standing: { complete: $r.measured.complete, valid: $r.measured.valid, schema: $r.measured.schema } }
    if not ($resolved.refused | is-empty) {
        return ($base | merge {
            dir: null, refused: $resolved.refused, last: null, census_frames: 0, measured: 0, outside: 0, invalid: 0, cut: [],
            directory: null, edge: null, lighting: [], problems: [], frames: [],
        })
    }
    let c = (census-of $resolved.dir $g $r)
    let refused = (if ($c.over | is-empty) { [] } else { [$"($c.over | length) census frames' mapped pixels past their rows' lit pixels, the first ($c.over | first | to nuon)"] })
    $base | merge ($c | reject over) | merge { dir: $resolved.dir, refused: $refused }
}

# A side's measured frames summarised, each context on its own
def side-summary [recs: list<record>, context_count: int]: nothing -> record {
    let valid = ($recs | where valid)
    let short = ($recs | where short)
    let long = ($recs | where long)
    let contexts = ($valid | get contexts | flatten)
    let fields = ($SIDE_FIELDS | reduce --fold {} {|f, acc| $acc | insert $f (spread ($valid | get $f)) })
    {
        frames: ($recs | length), valid: ($valid | length), short_windows: ($short | length), long_windows: ($long | length),
    } | merge $fields | merge {
        straddling_share: (spread ($valid | each {|s| ratio $s.straddling ($s.eligible + $s.straddling) })),
        straddling_pixel_share: (spread ($valid | each {|s| ratio $s.straddling_pixels ($s.eligible_pixels + $s.straddling_pixels) })),
        uniform_share: (spread ($valid | each {|s| ratio $s.uniform $s.demand })),
        checked: (sum-of ($valid | get checked)),
        mismatches: (sum-of ($valid | get mismatches)),
        w1: (spread ($valid | get w1)), p1: (spread ($valid | get p1)), q1: (spread ($valid | get q1)),
        w30: (spread ($short | get w30)), p30: (spread ($short | get p30)), q30: (spread ($short | get q30)),
        w120: (spread ($long | get w120)), p120: (spread ($long | get p120)), q120: (spread ($long | get q120)),
        context_requests: (spread ($contexts | get requests)),
        context_distinct: (spread ($contexts | get distinct)),
        context_surfaces: (spread ($contexts | get listed)),
        repeats: (spread ($contexts | where distinct > 0 | each {|c| $c.requests / $c.distinct })),
        per_context: (0..<$context_count | each {|i|
            let these = ($contexts | where context == $i)
            { context: $i, requests: (spread ($these | get requests)), distinct: (spread ($these | get distinct)), surfaces: (spread ($these | get listed)) }
        }),
        surface_tiles: (spread ($contexts | get counts | flatten)),
        ring: ($GUARANTEES | enumerate | each {|e| { guarantee: $e.item, fill: (spread ($contexts | each {|c| $c.fills | get $e.index })) } }),
        wall_context_distinct: (spread ($contexts | get wall_distinct)),
        wall_context_surfaces: (spread ($contexts | get wall_listed)),
        wall_surface_tiles: (spread ($contexts | get wall_counts | flatten)),
        wall_ring: ($GUARANTEES | enumerate | each {|e| { guarantee: $e.item, fill: (spread ($contexts | each {|c| $c.wall_fills | get $e.index })) } }),
    }
}

# TileCensus's reading of the batches under `base`
export def analyse [base: string, labels: list<string>]: nothing -> record {
    let requests = ($labels | each {|label|
        let report = ($base | path join $label "gauge.nuon")
        open $report | get runs | each {|r| { report: $report, run: $r.run } }
    } | flatten)
    let resolutions = (resolve-runs $requests)
    let batches = ($labels | each {|label|
        let report = ($base | path join $label "gauge.nuon")
        let g = (open $report)
        let runs = ($g.runs | each {|r| run-of $g $r ($resolutions | where report == $report and run == $r.run | first) })
        let recs = ($runs | where {|r| $r.refused | is-empty } | each {|r|
            let below = ($r.directory | get -o planes_below)
            $r.frames | each {|f|
                $f.sides | each {|s|
                    $s | reject contexts | merge {
                        run: $r.run, frame: $f.frame, leg: $f.leg, valid: $f.valid, short: $f.short, long: $f.long,
                        contexts: ($s.contexts | each {|c| context-of $c $below }),
                    }
                }
            } | flatten
        } | flatten)
        let legs = ($recs | get -o leg | uniq)
        let contexts = ($runs | where {|r| $r.refused | is-empty } | each {|r| $r.directory } | compact | each {|d| $d.contexts } | append 0 | math max)
        {
            label: $label,
            route: ($g.identity | get -o route.file | default "" | path basename),
            image: ($g.identity | get -o build.image_sha256),
            workers: ($g.rows | get -o workers | uniq),
            grains: ($g.rows | get -o grain | uniq),
            contexts: $contexts,
            runs: ($runs | reject frames),
            sides: ($SIDES | each {|side|
                let mine = ($recs | where side == $side)
                {
                    side: $side,
                    all: (side-summary $mine $contexts),
                    legs: ($legs | each {|leg| { leg: $leg } | merge (side-summary ($mine | where leg == $leg) $contexts) }),
                }
            }),
        }
    })
    let first_run = ($batches | get runs | flatten | where directory != null | get -o 0)
    {
        base: $base, labels: $labels,
        problems: ($batches | each {|b| $b.runs | each {|r| ($r.refused | each {|p| $"($b.label) run ($r.run) refused: ($p)" }) | append ($r.problems | each {|p| $"($b.label) run ($r.run): ($p)" }) } | flatten } | flatten),
        directory: (if $first_run == null { null } else { $first_run.directory }),
        slots: ($SIDES | each {|side|
            let tile = ($side * $side * $TEXEL_BYTES)
            { side: $side, tile_bytes: $tile } | merge ($POOLS_MIB | reduce --fold {} {|p, acc| $acc | insert $"mib_($p)" (($p * 1048576) // $tile) })
        }),
        guarantees: $GUARANTEES,
        batches: $batches,
    }
}

# TileCensus's reading saved to `out` and summarised
export def main [base: string, out: string, ...labels: string]: nothing -> nothing {
    let doc = (analyse $base $labels)
    $doc | to nuon --indent 1 | save --raw -f $out
    for b in $doc.batches {
        print $"tilecensus ($b.label): route ($b.route), workers ($b.workers | str join ','), runs ($b.runs | length), refused ($b.runs | where {|r| not ($r.refused | is-empty) } | length), measured census frames (sum-of ($b.runs | get measured)), invalid (sum-of ($b.runs | get invalid))"
        for s in $b.sides {
            let a = $s.all
            let ring = ($a.ring | where guarantee in [4 8 16] | each {|x| $"G($x.guarantee) ($x.fill.p99)/($x.fill.most)" } | str join ", ")
            print $"tilecensus   ($s.side): demand ($a.demand.median)/($a.demand.p95)/($a.demand.most), straddling ($a.straddling_share.median), uniform ($a.uniform_share.median); working ($a.w1.most), ($a.w30.most), ($a.w120.most); a surface's tiles ($a.surface_tiles.p95)/($a.surface_tiles.most); ring p99/most ($ring)"
        }
    }
    print $"tilecensus: ($doc.problems | length) problems; ($out)"
}
