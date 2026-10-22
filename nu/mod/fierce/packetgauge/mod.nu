use (path self ../../../../../jab/kit/fierce/nu/mod/gauge)

# The fields of a run's rows the reading spreads
const FIELDS = [draw_us critical_us report_us preparation_us raster_us commands packet_bytes]

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

# A leg's frames as the mode reads them, its building frames counted
def frames-of [mode: string, rows: list<any>]: nothing -> record {
    if $mode == "play" { return { built: null, frames: $rows } }
    let building = ($rows | enumerate | where {|e| ($e.item.tiles_built | default 0) > 0 } | get index)
    if ($building | is-empty) { return { built: 0, frames: [] } }
    { built: ($building | length), frames: ($rows | skip (($building | last) + 1)) }
}

# The identity's parts a comparison holds alike, the image apart
def held-alike [id: record]: nothing -> record {
    {
        kernel: ($id | get -o build.kernel_sha256),
        assets: ($id | get -o assets.digest),
        route: ($id | get -o route.sha256),
        toolchain: ($id | get -o toolchain.assembler),
        cadence: ($id | get -o mode.cadence),
        machine: ($id | get -o machine),
    }
}

# PacketGauge's reading of a battery: batches, builds, and differences
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
                cadence: $request.cadence, image: ($request.identity | get -o build.image_sha256), alike: (held-alike $request.identity),
                standing: { complete: $m.complete, valid: $m.valid, seeded: $m.seeded, schema: $m.schema, cadences: $m.cadences },
                l_answers: (if $mode == "settled" { l-answers ($r.out | path join "api.out") } else { null }),
                outcomes: $m.outcomes,
                legs: ($rows | get leg | uniq | where {|leg| $mode == "play" or $leg != "start" } | each {|leg|
                    let read = (frames-of $mode ($rows | where leg == $leg))
                    { leg: $leg, built: $read.built, frames: $read.frames }
                }),
            }
        })
        { label: $label, build: $build, images: ($runs | get image | uniq), runs: $runs }
    })
    let problems = ($batches | each {|b|
        $b.runs | each {|r|
            let s = $r.standing
            [
                (if $s.complete and $s.valid and $s.seeded { null } else { $"($b.label) run ($r.run): complete ($s.complete), valid ($s.valid), seeded ($s.seeded)" }),
                (if $s.cadences == [$r.cadence] { null } else { $"($b.label) run ($r.run): cadences ($s.cadences) where ($r.cadence) was asked" }),
                (if $mode == "settled" and $r.l_answers != (($r.legs | length)) { $"($b.label) run ($r.run): ($r.l_answers) L answers for ($r.legs | length) views" } else { null }),
                ($r.legs | where {|l| $mode == "settled" and ($l.built == 0 or ($l.frames | is-empty)) } | each {|l| $"($b.label) run ($r.run) ($l.leg): built ($l.built), settled ($l.frames | length)" }),
            ] | flatten | compact
        } | flatten
    } | flatten)
    let alike = ($batches | get runs | flatten | get alike | uniq)
    let legs = ($batches | get runs | flatten | get legs | flatten | get leg | uniq)
    let per_batch = ($batches | each {|b|
        {
            label: $b.label, build: $b.build,
            legs: ($legs | each {|leg|
                let frames = ($b.runs | each {|r| $r.legs | where leg == $leg | get -o 0.frames | default [] } | flatten)
                let count = {|f: string|
                    let values = ($frames | each {|x| $x | get -o $f })
                    if ($values | is-empty) or ($values | any {|v| $v == null }) { null } else { $values | math sum }
                }
                let invalidated = (do $count "invalidated")
                {
                    leg: $leg, frames: ($frames | length),
                    flushes: (do $count "flushes"), invalidated: $invalidated,
                    invalidating_frames: (if $invalidated == null { null } else { $frames | where {|x| $x.invalidated > 0 } | length }),
                } | merge ($FIELDS | reduce --fold {} {|f, acc| $acc | insert $f (spread ($frames | each {|x| $x | get -o $f })) })
            }),
        }
    })
    let builds = ($batches | get build | uniq)
    let per_build = ($builds | each {|bd|
        let these = ($per_batch | where build == $bd)
        {
            build: $bd, batches: ($these | get label),
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
            build: $b.build, from: $first.build,
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
        mode: $mode, problems: $problems, identities_alike: (($alike | length) == 1), identities: $alike,
        images: ($batches | each {|b| { label: $b.label, images: $b.images } }),
        outcomes: ($batches | each {|b| $b.runs | each {|r| { label: $b.label, run: $r.run, rounds: $r.outcomes.rounds, androids: $r.outcomes.androids, struck: $r.outcomes.struck, pickups: $r.outcomes.pickups } } } | flatten),
        batches: $per_batch, builds: $per_build, differences: $differences,
    }
}

# PacketGauge's reading saved to `out` and summarised
export def main [mode: string, base: string, out: string, ...labels: string]: nothing -> nothing {
    let doc = (analyse $mode $base $labels)
    $doc | to nuon --indent 1 | save --raw -f $out
    print $"packetgauge ($mode): ($labels | length) batches, ($doc.problems | length) problems, identities alike ($doc.identities_alike); ($out)"
}
