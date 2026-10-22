use (path self ../../../../../jab/kit/fierce/nu/mod/gauge)

# The fields a leg's frames are spread over, four derived among them
const FIELDS = [draw_us critical_us preparation_us raster_us slowest_us busy_us dispatch_us barrier_us imbalance_us remainder_us clear_us prepared_us outside_us game_us hud_us mix_us flip_us report_us]

# An API record's bytes
const RECORD = 64

# A console answer's kind in an API record
const KIND_CONSOLE = 11

# The console's L as its answer carries it, the command's byte at 4
const COMMAND_L = 76

# Least, median, 95th, and greatest by nearest rank, null-free
def spread [values: list<any>]: nothing -> record {
    let v = ($values | compact | sort)
    let n = ($v | length)
    if $n == 0 { return { n: 0, least: null, median: null, p95: null, most: null } }
    let rank = {|q: float| $v | get ((($q * $n) | math ceil) - 1) }
    { n: $n, least: ($v | first), median: (do $rank 0.5), p95: (do $rank 0.95), most: ($v | last) }
}

# The L answers a run's capture holds, -1 for no capture
def l-answers [api: path]: nothing -> int {
    if not ($api | path exists) { return (-1) }
    let b = (open --raw $api | into binary)
    0..<(($b | bytes length) // $RECORD) | each {|i| $b | bytes at ($i * $RECORD)..<(($i + 1) * $RECORD) }
    | where {|r| ($r | bytes at 0..<4 | into int --endian little) == $KIND_CONSOLE and ($r | bytes at 4..<8 | into int --endian little) == $COMMAND_L }
    | length
}

# A frame's derived fields: imbalance, remainder, preparation, outside
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

# A leg's frames as the mode reads them, each with its derived fields
def frames-of [mode: string, rows: list<any>]: nothing -> record {
    let read = (if $mode == "play" { { built: null, frames: $rows } } else {
        let building = ($rows | enumerate | where {|e| ($e.item.tiles_built | default 0) > 0 } | get index)
        if ($building | is-empty) { { built: 0, frames: [] } } else { { built: ($building | length), frames: ($rows | skip (($building | last) + 1)) } }
    })
    $read | update frames ($read.frames | each {|f| $f | merge (derived $f) })
}

# The identity's parts held alike, the workers and grain apart
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

# A run's harts' shares of a core over an older --threads' second
def harts-of [ran: record]: nothing -> list<any> {
    $ran | get -o threads | default [] | where {|t| $t.name =~ '^CPU \d+/TCG$' } | each {|t|
        { hart: ($t.name | parse 'CPU {n}/TCG' | get 0.n | into int), rate: $t.rate }
    } | sort-by hart
}

# Each CPU window over a build's runs: intervals and each hart's use
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

# WorkerGauge's reading of a battery: batches, builds, and differences
export def analyse [mode: string, base: string, labels: list<string>]: nothing -> record {
    if $mode not-in [settled play] { error make { msg: $"the mode is settled or play, not ($mode)" } }
    let batches = ($labels | each {|label|
        let file = ($base | path join $label "gauge.nuon")
        let g = (open $file)
        let build = ($label | str replace --regex '_\d+$' '')
        let runs = ($g.runs | each {|r|
            let rows = ($g.rows | where run == $r.run)
            let m = $r.measured
            let request = (gauge identity request $file $r ($g | get -o identity))
            {
                run: $r.run,
                identity: {
                    from: $request.from, file: $request.file, corrected: (if $request.corrections == null { [] } else { $request.corrections.fields | get field }),
                    binding: ($request.binding | get -o strength), unrecorded: ($request.binding | get -o unrecorded | default []), passed: $request.passed,
                },
                request: { selection: $request.selection, cadence: $request.cadence, workers: $request.workers, grain: $request.grain },
                alike: (held-alike $request.identity),
                standing: {
                    complete: $m.complete, valid: $m.valid, seeded: $m.seeded, schema: $m.schema, cadences: $m.cadences, workers: ($m | get -o workers), grains: ($m | get -o grains),
                    grants: ($m | get -o grants | default []), actives: ($m | get -o actives | default []),
                },
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
            workers: ($runs | get standing.workers | flatten | uniq | sort), grain: ($runs | get standing.grains | flatten | uniq | sort),
            grants: ($runs | get standing.grants | flatten | uniq | sort), actives: ($runs | get standing.actives | flatten | uniq | sort), runs: $runs,
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
            label: $b.label, build: $b.build, selection: $b.selection, workers: $b.workers, grain: $b.grain, grants: $b.grants, actives: $b.actives,
            harts: ($b.runs | each {|r| { run: $r.run, span: $r.span, harts: $r.harts } }),
            legs: ($legs | each {|leg|
                let frames = ($b.runs | each {|r| $r.legs | where leg == $leg | get -o 0.frames | default [] } | flatten)
                { leg: $leg, frames: ($frames | length) } | merge ($FIELDS | reduce --fold {} {|f, acc| $acc | insert $f (spread ($frames | each {|x| $x | get -o $f })) })
            }),
        }
    })
    let key_of = {|b| { build: $b.build, selection: $b.selection } }
    let builds = ($batches | each {|b| do $key_of $b } | uniq)
    let per_build = ($builds | each {|k|
        let these = ($per_batch | where {|t| (do $key_of $t) == $k })
        let runs = ($batches | where {|b| (do $key_of $b) == $k } | get runs | flatten)
        {
            build: $k.build, selection: ($these | first | get selection), batches: ($these | get label),
            workers: ($these | get workers | flatten | uniq | sort), grain: ($these | get grain | flatten | uniq | sort),
            grants: ($these | get grants | flatten | uniq | sort), actives: ($these | get actives | flatten | uniq | sort),
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

# WorkerGauge's reading saved to `out` and summarised
export def main [mode: string, base: string, out: string, ...labels: string]: nothing -> nothing {
    let doc = (analyse $mode $base $labels)
    $doc | to nuon --indent 1 | save --raw -f $out
    let corrected = ($doc.identities | where {|i| not ($i.corrected | is-empty) } | length)
    let reported = ($doc.identities | where {|i| $i.from != "file" } | length)
    let bindings = ($doc.identities | group-by {|i| $i.binding | default "none" } | transpose strength runs | each {|g| $"($g.runs | length) at ($g.strength)" } | str join ", ")
    let passed = ($doc.identities | each {|i| $i.passed | length } | math sum)
    let unrecorded = ($doc.identities | get unrecorded | flatten | uniq)
    print $"workergauge ($mode): ($labels | length) batches, ($doc.problems | length) problems, identities alike ($doc.identities_alike), ($corrected) corrected by their sidecars and ($reported) read from their reports; bound ($bindings), ($passed) directories passed over, unrecorded ($unrecorded | to nuon); ($out)"
}
