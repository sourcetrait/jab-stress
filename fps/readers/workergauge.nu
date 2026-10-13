# WorkerGauge's reading (FrameCeiling.md, TwoWorkers): the batteries'
# gauge.nuon files under one base directory, a batch a label, a build a
# label less its trailing _<n>, one image drawn by different workers and
# grains. `settled` reads each view leg's settled frames, those after the
# leg's last frame building a cell, and checks each run's capture for one
# L answer a view; `play` reads every frame of each leg. Untrimmed: per
# batch and leg the least, median, 95th, and greatest of each field a
# run's rows hold, and of four derived per frame: the imbalance, the
# slowest worker less the busy time over the workers; the remainder, the
# raster less the slowest worker, the dispatch, and the barrier, the
# coordinator's own time and the overlap of the three; the preparation
# less the clear, which the serial backend's preparation holds and the
# workers' bands take; and the critical path outside the drawing, the
# simulation, HUD, mix, flip, and report with what they leave
# unattributed; per build the mean of its batches' medians with half
# their range, and every build's difference from the first build named.
# The busy time is summed elapsed job time, never CPU. The CPU: each
# run's harts' shares of a core over the second an older `--threads` held,
# and from runs with `--cpu` the windows the report holds (gauge.nu's
# cpu-windows), per build each hart's CPU seconds and utilization per
# window with the runs' least and greatest, host-time windows never
# divided by frames. Each run's selection and request are its own
# identity's, read through gauge.nu's run-request, its source and
# corrections named, never the report's summary unless that is the
# identity's fallback. A batch's selection is its runs' agreement, and a
# batch whose runs mix the automatic and forced selections is refused even
# where they drew alike. Checked first: each run complete, valid, seeded,
# and at the cadence asked; a forced run drawn by the workers and grain it
# asked; an automatic run held to its frame records instead, drawn at one
# count and one grain, and its batch's runs at the same; and every run's
# identity alike, its build's flags and ELF among it, but for the workers
# and grain; each run's binding, the fields its report's identity left
# unrecorded, and every directory passed over named. A build is a label
# less its trailing _<n> under one selection, so an automatic build is
# never merged with a forced one of the same counts. Run under the real nu
# from a scratch justfile: `nu workergauge.nu <settled|play> <base>
# <out.nuon> <label>...`; its own fixtures `nu workergauge.nu holds
# <scratch>`.

const GAUGE = "../../../jab/game/fps/test/gauge.nu"
use $GAUGE [run-request]
use ./batches.nu [write-batch]

const FIELDS = [draw_us critical_us preparation_us raster_us slowest_us busy_us dispatch_us barrier_us imbalance_us remainder_us clear_us prepared_us outside_us game_us hud_us mix_us flip_us report_us]
const RECORD = 64
const KIND_CONSOLE = 11
# the console's L as its answer carries it, the command's byte at 4
const COMMAND_L = 76

# Least, median, 95th, and greatest by nearest rank, null-free.
def spread [values: list<any>]: nothing -> record {
    let v = ($values | compact | sort)
    let n = ($v | length)
    if $n == 0 { return { n: 0, least: null, median: null, p95: null, most: null } }
    let rank = {|q: float| $v | get ((($q * $n) | math ceil) - 1) }
    { n: $n, least: ($v | first), median: (do $rank 0.5), p95: (do $rank 0.95), most: ($v | last) }
}

# The L answers a run's capture holds.
def l-answers [api: path]: nothing -> int {
    if not ($api | path exists) { return (-1) }
    let b = (open --raw $api | into binary)
    0..<(($b | bytes length) // $RECORD) | each {|i| $b | bytes at ($i * $RECORD)..<(($i + 1) * $RECORD) }
    | where {|r| ($r | bytes at 0..<4 | into int --endian little) == $KIND_CONSOLE and ($r | bytes at 4..<8 | into int --endian little) == $COMMAND_L }
    | length
}

# A frame's derived fields: the imbalance, null under the serial backend;
# the remainder, the raster itself there; the preparation less the clear;
# and the critical path less the drawing.
def derived [row: record]: nothing -> record {
    let w = ($row | get -o workers)
    let worked = ($w != null and $w > 0)
    let preparation = ($row | get -o preparation_us)
    let critical = ($row | get -o critical_us)
    let draw = ($row | get -o draw_us)
    {
        imbalance_us: (if $worked { $row.slowest_us - ($row.busy_us / $w) } else { null }),
        remainder_us: (if $row.raster_us == null { null } else if $worked { $row.raster_us - $row.slowest_us - $row.dispatch_us - $row.barrier_us } else { $row.raster_us }),
        prepared_us: (if $preparation == null { null } else { $preparation - ($row | get -o clear_us | default 0) }),
        outside_us: (if $critical == null or $draw == null { null } else { $critical - $draw }),
    }
}

# A leg's frames as the mode reads them: every frame in play; in settled
# the frames after the leg's last frame building a cell, none when no
# frame built one.
def frames-of [mode: string, rows: list<any>]: nothing -> record {
    let read = (if $mode == "play" { { built: null, frames: $rows } } else {
        let building = ($rows | enumerate | where {|e| ($e.item.tiles_built | default 0) > 0 } | get index)
        if ($building | is-empty) { { built: 0, frames: [] } } else { { built: ($building | length), frames: ($rows | skip (($building | last) + 1)) } }
    })
    $read | update frames ($read.frames | each {|f| $f | merge (derived $f) })
}

# The identity's parts a comparison holds alike, the workers and grain
# apart: the build's image, flags, and ELF among them.
def held-alike [id: record]: nothing -> record {
    {
        image: ($id | get -o build.image_sha256),
        flags: ($id | get -o build.flags),
        elf: ($id | get -o build.elf_sha256),
        kernel: ($id | get -o build.kernel_sha256),
        assets: ($id | get -o assets.digest),
        route: ($id | get -o route.sha256),
        toolchain: ($id | get -o toolchain.assembler),
        cadence: ($id | get -o mode.cadence),
        machine: ($id | get -o machine),
    }
}

# A run's harts' shares of a core over the second an older `--threads`
# held, by hart.
def harts-of [ran: record]: nothing -> list<any> {
    $ran | get -o threads | default [] | where {|t| $t.name =~ '^CPU \d+/TCG$' } | each {|t|
        { hart: ($t.name | parse 'CPU {n}/TCG' | get 0.n | into int), rate: $t.rate }
    } | sort-by hart
}

# Each CPU window over a build's runs (gauge.nu's cpu-windows): by window,
# the runs holding it and those missing it, the actual interval's least
# and greatest, and for each hart's thread its utilization and CPU seconds
# least and greatest over the runs; none without readings.
def cpu-summary [runs: list<any>]: nothing -> list<any> {
    let windows = ($runs | each {|r|
        if $r.cpu == null { [] } else { [$r.cpu.whole] | append ($r.cpu.legs | each {|l| [$l] | append ($l | get -o subwindows | default []) } | flatten) }
    } | flatten)
    if ($windows | is-empty) { return [] }
    $windows | group-by window | transpose window entries | each {|g|
        let taken = ($g.entries | where {|w| not $w.missing })
        let intervals = ($taken | get interval)
        let threads = ($taken | each {|w| $w.threads } | flatten | where {|t| $t.name =~ '^CPU \d+/TCG$' } | group-by name | transpose name rows | each {|t|
            let u = ($t.rows | get utilization | compact)
            let s = ($t.rows | get cpu_seconds | compact)
            {
                thread: $t.name, runs: ($u | length),
                utilization: (if ($u | is-empty) { null } else { { least: ($u | math min), greatest: ($u | math max) } }),
                seconds: (if ($s | is-empty) { null } else { { least: ($s | math min), greatest: ($s | math max) } }),
            }
        } | sort-by thread)
        {
            window: $g.window, runs: ($g.entries | length), missing: (($g.entries | length) - ($taken | length)),
            interval: (if ($intervals | is-empty) { null } else { { least: ($intervals | math min), greatest: ($intervals | math max) } }),
            threads: $threads,
        }
    }
}

export def analyse [mode: string, base: string, labels: list<string>]: nothing -> record {
    if $mode not-in [settled play] { error make { msg: $"the mode is settled or play, not ($mode)" } }
    let batches = ($labels | each {|label|
        let file = ($base | path join $label "gauge.nuon")
        let g = (open $file)
        let build = ($label | str replace --regex '_\d+$' '')
        let runs = ($g.runs | each {|r|
            let rows = ($g.rows | where run == $r.run)
            let m = $r.measured
            let request = (run-request $file $r ($g | get -o identity))
            {
                run: $r.run,
                identity: {
                    from: $request.from, file: $request.file, corrected: (if $request.corrections == null { [] } else { $request.corrections.fields | get field }),
                    binding: ($request.binding | get -o strength), unrecorded: ($request.binding | get -o unrecorded | default []), passed: $request.passed,
                },
                request: { selection: $request.selection, cadence: $request.cadence, workers: $request.workers, grain: $request.grain },
                alike: (held-alike $request.identity),
                standing: { complete: $m.complete, valid: $m.valid, seeded: $m.seeded, schema: $m.schema, cadences: $m.cadences, workers: ($m | get -o workers), grains: ($m | get -o grains) },
                l_answers: (if $mode == "settled" { l-answers ($r.out | path join "api.out") } else { null }),
                harts: (harts-of ($r | get -o ran | default {})),
                span: ($r | get -o ran.threads_span),
                cpu: ($r | get -o cpu),
                outcomes: $m.outcomes,
                legs: ($rows | get leg | uniq | where {|leg| $mode == "play" or $leg != "start" } | each {|leg|
                    let read = (frames-of $mode ($rows | where leg == $leg))
                    { leg: $leg, built: $read.built, frames: $read.frames }
                }),
            }
        })
        let selections = ($runs | get request.selection | uniq)
        {
            label: $label, build: $build, selections: $selections,
            selection: (if ($selections | length) == 1 { $selections | first } else { null }),
            workers: ($runs | get standing.workers | flatten | uniq | sort), grain: ($runs | get standing.grains | flatten | uniq | sort), runs: $runs,
        }
    })
    let problems = ($batches | each {|b|
        let mixed = (if ($b.selections | length) > 1 { [$"($b.label): its runs mix the ($b.selections | str join ' and ') selections"] } else { [] })
        let spread = (if $b.selection == "automatic" and (($b.workers | length) > 1 or ($b.grain | length) > 1) {
            [$"($b.label): its automatic runs drew by workers ($b.workers) at grains ($b.grain), not one count at one grain"]
        } else { [] })
        $mixed | append $spread | append ($b.runs | each {|r|
            let s = $r.standing
            let q = $r.request
            [
                (if $s.complete and $s.valid and $s.seeded { null } else { $"($b.label) run ($r.run): complete ($s.complete), valid ($s.valid), seeded ($s.seeded)" }),
                (if $s.cadences == [$q.cadence] { null } else { $"($b.label) run ($r.run): cadences ($s.cadences) where ($q.cadence) was asked" }),
                (if $q.selection == "forced" {
                    if $s.workers == [$q.workers] and $s.grains == [$q.grain] { null } else { $"($b.label) run ($r.run): workers ($s.workers) at grains ($s.grains) where ($q.workers) at ($q.grain) was asked" }
                } else if ($s.workers | length) == 1 and ($s.grains | length) == 1 { null } else {
                    $"($b.label) run ($r.run): an automatic run drawn by workers ($s.workers) at grains ($s.grains), not one count at one grain"
                }),
                (if $mode == "settled" and $r.l_answers != (($r.legs | length)) { $"($b.label) run ($r.run): ($r.l_answers) L answers for ($r.legs | length) views" } else { null }),
                ($r.legs | where {|l| $mode == "settled" and ($l.built == 0 or ($l.frames | is-empty)) } | each {|l| $"($b.label) run ($r.run) ($l.leg): built ($l.built), settled ($l.frames | length)" }),
            ] | flatten | compact
        } | flatten)
    } | flatten)
    let every_run = ($batches | each {|b| $b.runs | each {|r| $r | insert label $b.label } } | flatten)
    let alike = ($every_run | get alike | uniq)
    let identities = ($every_run | each {|r| { label: $r.label, run: $r.run, from: $r.identity.from, binding: $r.identity.binding, unrecorded: $r.identity.unrecorded, passed: $r.identity.passed, corrected: $r.identity.corrected } })
    let legs = ($batches | get runs | flatten | get legs | flatten | get leg | uniq)
    let per_batch = ($batches | each {|b|
        {
            label: $b.label, build: $b.build, selection: $b.selection, workers: $b.workers, grain: $b.grain,
            harts: ($b.runs | each {|r| { run: $r.run, span: $r.span, harts: $r.harts } }),
            legs: ($legs | each {|leg|
                let frames = ($b.runs | each {|r| $r.legs | where leg == $leg | get -o 0.frames | default [] } | flatten)
                { leg: $leg, frames: ($frames | length) } | merge ($FIELDS | reduce --fold {} {|f, acc| $acc | insert $f (spread ($frames | each {|x| $x | get -o $f })) })
            }),
        }
    })
    # a build a label stem under one selection, never an automatic one
    # merged with a forced one of the same counts
    let key_of = {|b| { build: $b.build, selection: $b.selection } }
    let builds = ($batches | each {|b| do $key_of $b } | uniq)
    let per_build = ($builds | each {|k|
        let these = ($per_batch | where {|t| (do $key_of $t) == $k })
        let runs = ($batches | where {|b| (do $key_of $b) == $k } | get runs | flatten)
        {
            build: $k.build, selection: ($these | first | get selection), batches: ($these | get label),
            workers: ($these | get workers | flatten | uniq | sort), grain: ($these | get grain | flatten | uniq | sort),
            harts: ($these | get harts | flatten | get harts | flatten | group-by {|h| $h.hart | into string } | transpose hart entries | each {|g| { hart: ($g.hart | into int), rates: ($g.entries | get rate) } } | sort-by hart),
            cpu: (cpu-summary $runs),
            legs: ($legs | each {|leg|
                { leg: $leg } | merge ($FIELDS | reduce --fold {} {|f, acc|
                    let medians = ($these | each {|t| $t.legs | where leg == $leg | get 0 | get $f | get median } | compact)
                    let value = (if ($medians | length) != ($these | length) or ($medians | is-empty) { null } else {
                        { mean: ($medians | math avg), half: ((($medians | math max) - ($medians | math min)) / 2), medians: $medians }
                    })
                    $acc | insert $f $value
                })
            }),
        }
    })
    let first = ($per_build | first)
    let differences = ($per_build | skip 1 | each {|b|
        {
            build: $b.build, selection: $b.selection, from: $first.build, from_selection: $first.selection,
            legs: ($legs | each {|leg|
                let mine = ($b.legs | where leg == $leg | get 0)
                let theirs = ($first.legs | where leg == $leg | get 0)
                { leg: $leg } | merge ($FIELDS | reduce --fold {} {|f, acc|
                    let x = ($mine | get $f)
                    let y = ($theirs | get $f)
                    $acc | insert $f (if $x == null or $y == null { null } else { $x.mean - $y.mean })
                })
            }),
        }
    })
    {
        mode: $mode, problems: $problems, identities_alike: (($alike | length) == 1), alike: $alike, identities: $identities,
        outcomes: ($batches | each {|b| $b.runs | each {|r| { label: $b.label, run: $r.run, rounds: $r.outcomes.rounds, androids: $r.outcomes.androids, struck: $r.outcomes.struck, pickups: $r.outcomes.pickups } } } | flatten),
        batches: $per_batch, builds: $per_build, differences: $differences,
    }
}

def main [mode: string, base: string, out: string, ...labels: string] {
    let doc = (analyse $mode $base $labels)
    $doc | to nuon --indent 1 | save --raw -f $out
    let corrected = ($doc.identities | where {|i| not ($i.corrected | is-empty) } | length)
    let reported = ($doc.identities | where {|i| $i.from != "file" } | length)
    let bindings = ($doc.identities | group-by {|i| $i.binding | default "none" } | transpose strength runs | each {|g| $"($g.runs | length) at ($g.strength)" } | str join ", ")
    let passed = ($doc.identities | each {|i| $i.passed | length } | math sum)
    let unrecorded = ($doc.identities | get unrecorded | flatten | uniq)
    print $"workergauge ($mode): ($labels | length) batches, ($doc.problems | length) problems, identities alike ($doc.identities_alike), ($corrected) corrected by their sidecars and ($reported) read from their reports; bound ($bindings), ($passed) directories passed over, unrecorded ($unrecorded | to nuon); ($out)"
}

# The reader's own fixtures over synthetic batches it writes under
# `scratch` (batches.nu), each case's reading run under its name so a
# raise fails it by name: an automatic batch and a forced one of one
# build drawn alike, both accepted and kept as two builds with separate
# results; a summary asking none over forced runs and one asking workers
# over automatic runs, the runs' selections standing; a batch whose runs
# mix the two selections refused; and a forced run drawn by other workers
# than it asked and an automatic run drawn at two counts, each refused by
# name.
def "main holds" [scratch: string] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    mkdir $scratch
    let fail = {|name: string, why: string| error make { msg: $"workergauge holds: ($name): ($why)" } }
    let named = {|name: string, work: closure| try { do $work } catch {|e| do $fail $name $"raised: ($e.msg | str substring 0..300)" } }
    let refused = {|name: string, read: record, says: string|
        if not ($read.problems | any {|p| $p | str contains $says }) { do $fail $name $"refused for ($read.problems | str join '; ')" }
    }
    let forced = { build: { image_sha256: "holds_image" }, mode: { cadence: 0, workers: 2, grain: 0 } }
    let automatic = { build: { image_sha256: "holds_image" }, mode: { cadence: 0 } }
    let two = [[2 0] [2 0] [2 0]]
    let run_of = {|id: record, drawn: list<any>| { identity: $id, cadence: 0, drawn: $drawn } }

    # one build's batches, one forced and one automatic, drawn alike
    let pair = ($scratch | path join "pair")
    write-batch $pair "pair_1" $forced [(do $run_of $forced $two) (do $run_of $forced $two)] | ignore
    write-batch $pair "pair_2" $automatic [(do $run_of $automatic $two) (do $run_of $automatic $two)] | ignore
    let paired = (do $named "the pair read" { analyse "play" $pair [pair_1 pair_2] })
    if not ($paired.problems | is-empty) { do $fail "an automatic batch and a forced one drawn alike are accepted" ($paired.problems | str join "; ") }
    let kept = ($paired.builds | each {|b| [$b.build $b.selection $b.batches] })
    if $kept != [[pair forced [pair_1]] [pair automatic [pair_2]]] { do $fail "the pair kept as two builds with separate results" ($kept | to nuon) }

    # the summary disagreeing with its runs both ways
    let disagree = ($scratch | path join "disagree")
    write-batch $disagree "nullsum_1" $automatic [(do $run_of $forced $two)] | ignore
    write-batch $disagree "forcedsum_1" ($forced | update mode.workers 1 | update mode.grain 16) [(do $run_of $automatic $two)] | ignore
    let nullsum = (do $named "a summary asking none over forced runs" { analyse "play" $disagree [nullsum_1] })
    let nullsum_says = [$nullsum.problems ($nullsum.builds | get 0.selection)]
    if $nullsum_says != [[] forced] { do $fail "a summary asking none over forced runs leaves them forced" ($nullsum_says | to nuon) }
    let forcedsum = (do $named "a summary asking workers over automatic runs" { analyse "play" $disagree [forcedsum_1] })
    let forcedsum_says = [$forcedsum.problems ($forcedsum.builds | get 0.selection)]
    if $forcedsum_says != [[] automatic] { do $fail "a summary asking workers over automatic runs leaves them automatic" ($forcedsum_says | to nuon) }

    # a batch mixing the selections, a forced run drawn by other workers,
    # and an automatic run drawn at two counts
    let refusals = ($scratch | path join "refusals")
    write-batch $refusals "mixed_1" $forced [(do $run_of $forced $two) (do $run_of $automatic $two)] | ignore
    write-batch $refusals "other_1" $forced [(do $run_of $forced [[1 0] [1 0] [1 0]])] | ignore
    write-batch $refusals "counts_1" $automatic [(do $run_of $automatic [[1 0] [2 0] [2 0]])] | ignore
    let mixed = (do $named "a batch mixing the selections" { analyse "play" $refusals [mixed_1] })
    do $refused "a batch mixing the two selections is refused" $mixed "mixed_1: its runs mix the forced and automatic selections"
    let other = (do $named "a forced run drawn by other workers" { analyse "play" $refusals [other_1] })
    do $refused "a forced run drawn by other workers than it asked is refused" $other "other_1 run 1: workers [1] at grains [0] where 2 at 0 was asked"
    let counts = (do $named "an automatic run drawn at two counts" { analyse "play" $refusals [counts_1] })
    do $refused "an automatic run drawn at two counts is refused" $counts "counts_1 run 1: an automatic run drawn by workers [1, 2] at grains [0], not one count at one grain"
    print "workergauge holds: ok"
}
