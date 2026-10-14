# TileCensus's reading (FrameCeiling.md, TilePool): a CENSUS build's runs of
# the gauge's routes, a batch a label under one base directory holding its
# gauge.nuon and each run's serial.log, the census's lines read by jab's
# `test/census.nu`. A run is refused before its census is read unless its
# capture is complete and valid (GaugeStanding) and its directory is the one
# whose identity file binds to the run's recorded SHA-256, through gauge.nu's
# identity-of, the identity's seed the run's (CensusRunBinding), resolved in
# a nu of its own (tilecensus_resolve.nu) since gauge.nu loaded here would
# slow the census's parse about eightfold; and after,
# when a census frame's mapped pixels at side 32, eligible plus straddling,
# pass its row's lit pixels, the two files then not one run's. A refused
# run is summarized nowhere. Every census frame of an accepted run takes the
# leg the gauge's row of the same frame names; frames past the
# measurement's final frame are counted outside and read no further. A frame
# stands valid as census.nu judges it, whole and accounting; a working set
# over 30 or 120 frames stands only when every frame of its window is present
# and valid, the window whole since the census's first frame. Per batch,
# side, and leg, and over every leg: the eligible and straddling blocks and
# their shares, the demand by class, the sampled and uniformly lit tiles,
# the working sets by class, the requesting surfaces, each context's
# requests, distinct tiles, and surfaces, the distinct tiles a surface asks
# of a context in a frame, and the open ring's fill past each guarantee in
# GUARANTEES, a context's distinct tiles past each surface's first G summed,
# these for every surface and again for the walls with their openings alone,
# the surfaces from the directory's planes-below on, the class TILE_CLASSES
# caches first; untrimmed, by nearest rank. Beside them the directory's bytes
# and the pool's slots at each side for each size in POOLS_MIB. Problems
# named besides: a refusal, the rows not every frame from 0, no directory, the
# edge's verdicts not both 0, a gap, a measured frame with no census or
# invalid, a mismatch, more than one lighting revision. Run under the real nu
# from a scratch justfile: `nu tilecensus.nu <base> <out.nuon> <label>...`;
# its own fixtures `nu tilecensus.nu holds <base> <scratch>`.

use ../../../jab/game/fps/test/census.nu

const RESOLVER = (path self | path dirname | path join "tilecensus_resolve.nu")

const SIDES = [32 64 128]
const GUARANTEES = [0 1 2 4 8 16 32 64]
const POOLS_MIB = [16 32]
const TEXEL_BYTES = 4
const SHORT = 30
const WINDOW = 120
const SIDE_FIELDS = [eligible straddling outside demand planes walls openings sampled uniform surfaces]
# the holds' batches under their base: the archive's, three contexts, and
# one on eight harts whose directories count eight
const ARCHIVE = "census_settled_w0"
const EIGHT = "census_settled_h8"
# the side whose mapped pixels are held to the rows' lit pixels
const BOUND_SIDE = 32

# Least, median, 95th, 99th, and greatest by nearest rank, nulls dropped.
def spread [values: list<any>]: nothing -> record {
    let v = ($values | compact | sort)
    let n = ($v | length)
    if $n == 0 { return { n: 0, least: null, median: null, p95: null, p99: null, most: null } }
    let rank = {|q: float| $v | get ((($q * $n) | math ceil) - 1) }
    { n: $n, least: ($v | first), median: (do $rank 0.5), p95: (do $rank 0.95), p99: (do $rank 0.99), most: ($v | last) }
}

def ratio [part: int, whole: int]: nothing -> any {
    if $whole == 0 { null } else { $part / $whole }
}

# A sum that reads an empty list as 0, where math sum refuses it.
def sum-of [values: list<any>]: nothing -> number {
    if ($values | is-empty) { 0 } else { $values | math sum }
}

# The open ring's fill past each guarantee: the counts past G summed.
def fills-of [counts: list<int>]: nothing -> list<int> {
    $GUARANTEES | each {|g| sum-of ($counts | each {|n| if $n > $g { $n - $g } else { 0 } }) }
}

# A context's list folded to what the summaries read: its counts and the
# open ring's fill past each guarantee, for every surface and for the walls
# with their openings alone, the surfaces from `below`, the directory's
# planes-below, the class TILE_CLASSES caches first.
def context-of [c: record, below: oneof<int, nothing>]: nothing -> record {
    let counts = ($c.pairs | get count)
    let walls = (if $below == null { [] } else { $c.pairs | where surface >= $below | get count })
    {
        context: $c.context, requests: $c.requests, distinct: $c.distinct, listed: $c.listed, counts: $counts,
        fills: (fills-of $counts),
        wall_counts: $walls, wall_distinct: (sum-of $walls), wall_listed: ($walls | length), wall_fills: (fills-of $walls),
    }
}

# Where each requested run's census is, or why it is refused before it is
# read, each request a report and a run number in it, resolved in a nu of
# its own (tilecensus_resolve.nu): GaugeStanding and CensusRunBinding.
export def resolve-runs [requests: list<record<report: string, run: int>>]: nothing -> list<record> {
    let r = (^nu $RESOLVER ($requests | to nuon) | complete)
    if $r.exit_code != 0 { error make { msg: $"the run resolver failed: ($r.stderr)" } }
    $r.stdout | from nuon
}

# A resolved run's census: its rows' legs, its census frames, the measured
# ones marked with their leg and their windows' standing, the frames whose
# mapped pixels pass their rows' lit pixels, and what keeps it from whole.
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

# One run of a batch under its resolution: refused, or its census read,
# refused whole when a frame's mapped pixels pass its row's lit pixels.
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

# A side's records, one a measured frame, summarised, each of the
# `context_count` contexts its directories count on its own.
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
        # the contexts the accepted runs' directories count, never the
        # context lines that arrived
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

def main [base: string, out: string, ...labels: string] {
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

# The reader's own fixtures over a saved battery's settled batch at W 0 and
# altered copies of it under `scratch`, every report the resolver reads
# written there and resolved in one call, each refusal taken before its
# census is read and named with its reason, the archive the positive
# control: the batch's run accepted, resolved beside its report, its census
# whole; a capture complete and invalid, and one incomplete, refused
# (GaugeStanding); two runs' directories swapped, an identity hash missing,
# one mismatched, and a run's seed not its identity's, each refused, while
# the batch moved elsewhere resolves every run beside its report
# (CensusRunBinding); a census frame's mapped pixels raised past its row's
# lit pixels, the run refused and summarized nowhere; one census frame made
# invalid and another removed, every 30-frame window from each to 29 frames
# on and every 120-frame window to 119 on read invalid, each valid again at
# 30 and 120 frames on, both named as problems; and the other problems
# named: the edge's verdicts, a second lighting revision, a mismatch, an
# unparsed frame line, the gaps, rows not every frame from 0, no directory;
# the archive read over the three contexts its directories count, and
# beside it a copy of run 1 of a batch on eight harts read over its
# directory's eight, accepted and its census whole, and a copy of it under
# a first-format directory read over that directory's three, every frame
# invalid.
def "main holds" [base: string, scratch: string] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    mkdir $scratch
    let label = $ARCHIVE
    let report = ($base | path join $label "gauge.nuon")
    let g = (open $report)
    let r1 = ($g.runs | where run == 1 | first)
    let fail = {|name: string, why: string| error make { msg: $"tilecensus holds: ($name): ($why)" } }
    let refuses = {|name: string, got: record, reason: string|
        if ($got.refused | is-empty) { do $fail $name "accepted" }
        if not ($got.refused | any {|x| $x | str contains $reason }) { do $fail $name $"refused for ($got.refused | str join '; ')" }
    }
    let names = {|name: string, got: record, text: string|
        if not ($got.problems | any {|x| $x | str contains $text }) { do $fail $name ($got.problems | str join "; ") }
    }
    # a copy of the report changed by `put`, its recorded outs the archive's
    let altered = {|case: string, put: closure|
        let dir = ($scratch | path join $case)
        mkdir $dir
        do $put $g | to nuon | save ($dir | path join "gauge.nuon")
        ($dir | path join "gauge.nuon")
    }
    let run_put = {|run: int, put: closure| {|gr| $gr | update runs ($gr.runs | each {|r| if $r.run == $run { do $put $r } else { $r } }) } }
    # a copy of the batch's runs, run n's files from run (from n), its outs
    # under `outs`
    let copied = {|case: string, from: closure, outs: string|
        let dir = ($scratch | path join $case)
        for n in [1 2 3] {
            let d = ($dir | path join $"run_($n)")
            mkdir $d
            for f in ["identity.nuon" "serial.log"] { cp ($base | path join $label $"run_(do $from $n)" $f) ($d | path join $f) }
        }
        $g | update runs ($g.runs | each {|r| $r | update out ($outs | path join $"run_($r.run)") }) | to nuon | save ($dir | path join "gauge.nuon")
        ($dir | path join "gauge.nuon")
    }
    let invalid = (do $altered "invalid" (do $run_put 1 {|r| $r | update measured.valid false }))
    let incomplete = (do $altered "incomplete" (do $run_put 1 {|r| $r | update measured.complete false }))
    let unhashed = (do $altered "unhashed" (do $run_put 3 {|r| $r | update identity_sha256 null }))
    let mishashed = (do $altered "mishashed" (do $run_put 3 {|r| $r | update identity_sha256 (0..<64 | each { "0" } | str join) }))
    let reseeded = (do $altered "reseeded" (do $run_put 1 {|r| $r | update seed 99 }))
    let unordered = (do $altered "unordered" {|gr| $gr | update rows ($gr.rows | where {|row| not ($row.run == 1 and $row.frame == 0) }) })
    let swapped = (do $copied "swapped" {|n| if $n == 1 { 3 } else if $n == 3 { 1 } else { $n } } ($scratch | path join "swapped"))
    let moved = (do $copied "moved" {|n| $n } ($scratch | path join "gone"))
    let window = (do $copied "window" {|n| $n } ($scratch | path join "window"))
    let undirected = (do $copied "undirected" {|n| $n } ($scratch | path join "undirected"))
    # the window copy: frame 200 made invalid, frame 450 removed, the edge
    # read shaded, frame 600 at a second lighting revision, frame 620 a
    # mismatch, frame 640's frame line unparsed; the undirected copy without
    # its directory
    let broken = 200
    let gone = 450
    let lines = (open --raw ($base | path join $label "run_1" "serial.log") | decode | lines | enumerate)
    let span = {|f: int| { from: ($lines | where {|e| $e.item starts-with $"fps: census frame ($f):" } | get 0.index), to: ($lines | where {|e| $e.item == $"fps: census end ($f)" } | get 0.index) } }
    let b = (do $span $broken)
    let r = (do $span $gone)
    let m = (do $span 620)
    $lines | where {|e| not (($e.index >= $r.from and $e.index <= $r.to) or ($e.index > $b.from and $e.index < $b.to and ($e.item starts-with "fps: census 64 context 1"))) } | each {|e|
        let l = $e.item
        if $l starts-with "fps: census edge: " { "fps: census edge: nodes 1, sampler 0" } else if $l starts-with "fps: census frame 600:" { $l | str replace ", lighting 0," ", lighting 1," } else if $l starts-with "fps: census frame 640:" { "fps: census frame 640: blocks" } else if ($e.index > $m.from and $e.index < $m.to and ($l starts-with "fps: census 32: ")) {
            let c = ($l | parse --regex 'checked (?<c>\d+), mismatches (?<m>\d+)' | first)
            $l | str replace $"checked ($c.c), mismatches ($c.m)" $"checked (($c.c | into int) + 1), mismatches (($c.m | into int) + 1)"
        } else { $l }
    } | str join (char nl) | save -f ($scratch | path join "window" "run_1" "serial.log")
    $lines | get item | where {|l| not ($l starts-with "fps: census directory: ") } | str join (char nl) | save -f ($scratch | path join "undirected" "run_1" "serial.log")
    let requests = [
        { report: $report, run: 1 }
        { report: $invalid, run: 1 }
        { report: $incomplete, run: 1 }
        { report: $swapped, run: 3 }
        { report: $unhashed, run: 3 }
        { report: $mishashed, run: 3 }
        { report: $reseeded, run: 1 }
        { report: $unordered, run: 1 }
        { report: $moved, run: 1 }
        { report: $moved, run: 2 }
        { report: $moved, run: 3 }
        { report: $window, run: 1 }
        { report: $undirected, run: 1 }
    ]
    let answers = (resolve-runs $requests)
    let answer = {|rep: string, run: int| $answers | where report == $rep and run == $run | first }

    # the archive's run accepted, resolved beside its report, its census whole
    let ok = (do $answer $report 1)
    if not ($ok.refused | is-empty) or $ok.dir != ($base | path join $label "run_1") { do $fail "the archive's run accepted" ($ok | to nuon) }
    let whole = (run-of $g $r1 $ok)
    if not ($whole.refused | is-empty) or $whole.invalid > 0 or not ($whole.problems | is-empty) { do $fail "the archive's census whole" ($whole | reject frames | to nuon) }

    # GaugeStanding
    do $refuses "a capture complete and invalid" (do $answer $invalid 1) "valid false"
    do $refuses "a capture incomplete" (do $answer $incomplete 1) "complete false"

    # CensusRunBinding
    do $refuses "two runs' directories swapped" (do $answer $swapped 3) "no identity file binds"
    do $refuses "an identity hash missing" (do $answer $unhashed 3) "no identity file binds"
    do $refuses "an identity hash mismatched" (do $answer $mishashed 3) "no identity file binds"
    do $refuses "a run's seed not its identity's" (do $answer $reseeded 1) "seed"
    for n in [1 2 3] {
        let got = (do $answer $moved $n)
        if not ($got.refused | is-empty) or $got.dir != ($scratch | path join "moved" $"run_($n)") { do $fail "the batch moved resolves its runs beside its report" ($got | to nuon) }
    }

    # a census frame's mapped pixels past its row's lit pixels: the run
    # refused, and summarized nowhere
    let probe = ($whole.frames | where valid | get 100)
    let s = ($probe.sides | where side == $BOUND_SIDE | first)
    let mapped = ($s.eligible_pixels + $s.straddling_pixels)
    let lower = {|gr| $gr | update rows ($gr.rows | each {|row| if $row.run == 1 and $row.frame == $probe.frame { $row | update lit_pixels ($mapped - 1) } else { $row } }) }
    do $refuses "a census frame's mapped pixels past its row's lit pixels" (run-of (do $lower $g) $r1 $ok) "past their rows' lit pixels"
    let summed = ($scratch | path join "summed")
    mkdir ($summed | path join $label)
    do $lower $g | to nuon | save ($summed | path join $label "gauge.nuon")
    let doc = (analyse $summed [$label])
    let batch = ($doc.batches | first)
    let accepted = ($batch.runs | where {|x| $x.refused | is-empty })
    let counted = ($batch.sides | where side == $BOUND_SIDE | first | get all.frames)
    if ($accepted | length) != 2 or $counted != ($accepted | get measured | math sum) { do $fail "a refused run summarized nowhere" $"($accepted | length) runs accepted, ($counted) frames summarized" }
    let per3 = ($batch.sides | each {|s| $s.all.per_context | length })
    if $batch.contexts != 3 or ($per3 | any {|n| $n != 3 }) { do $fail "the archive read over its directories' three contexts" $"contexts ($batch.contexts), per side ($per3)" }

    # the windows
    let gw = (open $window)
    let read = (run-of $gw ($gw.runs | where run == 1 | first) (do $answer $window 1))
    if not ($read.refused | is-empty) { do $fail "the window copy accepted" ($read.refused | str join "; ") }
    let flags = ($read.frames | reduce --fold {} {|f, acc| $acc | insert ($f.frame | into string) { valid: $f.valid, short: $f.short, long: $f.long } })
    let flag = {|f: int, k: string| $flags | get ($f | into string) | get $k }
    if (do $flag $broken valid) { do $fail "the broken frame invalid" "read valid" }
    if not ((do $flag ($broken - 1) short) and (do $flag ($broken - 1) long)) { do $fail "the windows before the broken frame" "invalid" }
    if (($broken)..($broken + 29) | each {|f| do $flag $f short } | any {|x| $x }) { do $fail "an invalid frame's 30-frame windows" "one read valid" }
    if not (do $flag ($broken + 30) short) { do $fail "the 30-frame windows' recovery after an invalid frame" "not valid again" }
    if (($broken)..($broken + 119) | each {|f| do $flag $f long } | any {|x| $x }) { do $fail "an invalid frame's 120-frame windows" "one read valid" }
    if not (do $flag ($broken + 120) long) { do $fail "the 120-frame windows' recovery after an invalid frame" "not valid again" }
    if ($flags | get -o ($gone | into string)) != null { do $fail "the removed frame" "read" }
    if (($gone + 1)..($gone + 29) | each {|f| do $flag $f short } | any {|x| $x }) { do $fail "a missing frame's 30-frame windows" "one read valid" }
    if not (do $flag ($gone + 30) short) { do $fail "the 30-frame windows' recovery after a missing frame" "not valid again" }
    if (($gone + 1)..($gone + 119) | each {|f| do $flag $f long } | any {|x| $x }) { do $fail "a missing frame's 120-frame windows" "one read valid" }
    if not (do $flag ($gone + 120) long) { do $fail "the 120-frame windows' recovery after a missing frame" "not valid again" }

    # the problems named
    do $names "an invalid frame named" $read "measured census frames invalid"
    do $names "a missing frame named" $read "with no census"
    do $names "gaps named" $read "gaps in the census frames"
    do $names "an edge's verdicts named" $read "the census edge read nodes 1"
    do $names "a second lighting revision named" $read "lighting revisions"
    do $names "a mismatch named" $read "uniform verdicts the sampler refused"
    do $names "an unparsed frame line named" $read "frame line does not parse"
    do $names "rows not every frame from 0 named" (run-of (open $unordered) $r1 (do $answer $unordered 1)) "not every frame from 0"
    let gu = (open $undirected)
    do $names "no directory named" (run-of $gu ($gu.runs | where run == 1 | first) (do $answer $undirected 1)) "the log holds no census directory"

    # the eight-context batch's run 1 beside the archive, copied whole, then
    # copied under a first-format directory, its contexts the directory's
    # three; a run each, the reading's cost an eight-context log's
    let g8 = (open ($base | path join $EIGHT "gauge.nuon"))
    let one8 = ($g8 | update runs ($g8.runs | where run == 1) | update rows ($g8.rows | where run == 1))
    let copy_one = {|case: string, line: closure|
        let from = ($base | path join $EIGHT "run_1")
        let d = ($scratch | path join $case $EIGHT "run_1")
        mkdir $d
        cp ($from | path join "identity.nuon") ($d | path join "identity.nuon")
        open --raw ($from | path join "serial.log") | decode | lines | each {|l| do $line $l } | str join (char nl) | save ($d | path join "serial.log")
        $one8 | update runs ($one8.runs | each {|r| $r | update out $d }) | to nuon | save ($scratch | path join $case $EIGHT "gauge.nuon")
        ($scratch | path join $case)
    }
    let eight = (analyse (do $copy_one "eight" {|l| $l }) [$EIGHT])
    let b8 = ($eight.batches | first)
    if not ($eight.problems | is-empty) { do $fail "the eight-context batch accepted, its census whole" ($eight.problems | str join "; ") }
    let per8 = ($b8.sides | each {|s| $s.all.per_context | length })
    if ($b8.runs | length) != 1 or $b8.contexts != 8 or ($per8 | any {|n| $n != 8 }) { do $fail "the eight-context batch read over its directories' eight contexts" $"runs ($b8.runs | length), contexts ($b8.contexts), per side ($per8)" }
    let bf = (analyse (do $copy_one "first_format" {|l| if ($l starts-with "fps: census directory: ") { $l | str replace --regex ', contexts \d+;' ';' } else { $l } }) [$EIGHT] | get batches | first)
    if $bf.contexts != 3 { do $fail "a first-format directory over eight contexts read as three" $"contexts ($bf.contexts)" }
    let read_f = ($bf.runs | where {|x| $x.refused | is-empty })
    if ($read_f | length) != 1 or ($read_f | any {|x| $x.measured == 0 or $x.invalid != $x.measured }) { do $fail "a first-format directory over eight contexts leaves every frame invalid" ($bf.runs | select run measured invalid | to nuon) }
    print "tilecensus holds: ok"
}
