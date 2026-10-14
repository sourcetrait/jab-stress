# GfxScaling's gain curves (FrameCeiling.md, GfxScaling): a battery's
# builds, checked and keyed as workergauge.nu reads them, each build's
# critical path by leg and over the whole route: the mean of its batches'
# medians with half their range, each run's own median over the same
# frames with the runs' least and greatest, the frames at or over the
# ceiling, and whether the mean sits under it (MedianCeiling's
# CEILING_US). `settled` reads each view leg's frames after its last
# building frame, `play` every frame of each leg; the whole route is every
# leg's frames read together. A battery in which workergauge finds any
# problem is refused before any summary, each problem named, and `table`
# refuses a reading that carries one (GainCurvesRefusal). Run under the
# real nu from a scratch justfile: `nu gaincurves.nu <settled|play> <base>
# <out.nuon> <label>...`; `table` renders a reading's builds as a markdown
# table in milliseconds; its own fixtures `nu gaincurves.nu holds
# <scratch>`.
use ./workergauge.nu [analyse]
use ./batches.nu [write-batch]

const CEILING_US = 15000

# The frames a leg's run is read on, workergauge's settled rule.
def read-frames [mode: string, rows: list<any>]: nothing -> list<any> {
    if $mode == "play" { return $rows }
    let building = ($rows | enumerate | where {|e| ($e.item.tiles_built | default 0) > 0 } | get index)
    if ($building | is-empty) { [] } else { $rows | skip (($building | last) + 1) }
}

# The median by nearest rank, workergauge's spread's.
def median-of [values: list<any>]: nothing -> any {
    let v = ($values | compact | sort)
    if ($v | is-empty) { return null }
    $v | get (((($v | length) * 0.5) | math ceil) - 1)
}

# A set of frames' reading: its batches' medians' mean and half range,
# its runs' medians' least and greatest, the frames over the ceiling.
def reading [batches: list<list<any>>, runs: list<list<any>>]: nothing -> record {
    let bm = ($batches | each {|f| median-of $f } | compact)
    let rm = ($runs | each {|f| median-of $f } | compact)
    let frames = ($batches | flatten)
    {
        mean: (if ($bm | is-empty) { null } else { $bm | math avg }),
        half: (if ($bm | is-empty) { null } else { (($bm | math max) - ($bm | math min)) / 2 }),
        run_least: (if ($rm | is-empty) { null } else { $rm | math min }),
        run_most: (if ($rm | is-empty) { null } else { $rm | math max }),
        over: ($frames | where {|c| $c >= $CEILING_US } | length),
        frames: ($frames | length),
        under: (if ($bm | is-empty) { null } else { ($bm | math avg) < $CEILING_US }),
    }
}

# The battery's curves, refused before any summary when workergauge finds
# a problem in it, every problem named.
export def curves [mode: string, base: string, labels: list<string>]: nothing -> record {
    let doc = (analyse $mode $base $labels)
    if not ($doc.problems | is-empty) {
        error make { msg: $"gaincurves: the battery has problems, so no curves are read: ($doc.problems | str join '; ')" }
    }
    let batches = ($labels | each {|label|
        let g = (open ($base | path join $label "gauge.nuon"))
        let runs = ($g.runs | each {|r|
            let rows = ($g.rows | where run == $r.run)
            let legs = ($rows | get leg | uniq | where {|leg| $mode == "play" or $leg != "start" })
            { run: $r.run, legs: ($legs | each {|leg| { leg: $leg, critical: (read-frames $mode ($rows | where leg == $leg) | get critical_us) } }) }
        })
        { label: $label, runs: $runs }
    })
    let builds = ($doc.builds | each {|b|
        let mine = ($batches | where {|x| $x.label in $b.batches })
        let legs = ($mine | get runs | flatten | get legs | flatten | get leg | uniq)
        let of = {|r: record, leg: string| $r.legs | where leg == $leg | get -o 0.critical | default [] }
        let per_leg = ($legs | each {|leg|
            { leg: $leg } | merge (reading ($mine | each {|x| $x.runs | each {|r| do $of $r $leg } | flatten }) ($mine | get runs | flatten | each {|r| do $of $r $leg }))
        })
        let whole = (reading ($mine | each {|x| $x.runs | get legs | flatten | get critical | flatten }) ($mine | get runs | flatten | each {|r| $r.legs | get critical | flatten }))
        {
            build: $b.build, selection: $b.selection, batches: $b.batches, workers: $b.workers, grain: $b.grain, grants: $b.grants, actives: $b.actives,
            legs: $per_leg, whole: $whole,
            legs_under: ($per_leg | where under == true | length), legs_read: ($per_leg | where mean != null | length),
        }
    })
    { mode: $mode, base: $base, problems: $doc.problems, identities_alike: $doc.identities_alike, alike: $doc.alike, builds: $builds }
}

# A reading's builds as a markdown table, the legs down and the builds
# across in the order named, each cell the mean of the batches' medians in
# milliseconds with half their range and the runs' least and greatest
# medians in brackets; the whole route's last, then the frames at or over
# the ceiling of those read. A reading recording no problems field, or
# carrying any problem, is refused, every problem named.
export def table-of [c: record, builds: list<string>]: nothing -> string {
    let problems = ($c | get -o problems)
    if $problems == null { error make { msg: "gaincurves table: the reading records no problems, so it is no reading of curves" } }
    if not ($problems | is-empty) { error make { msg: $"gaincurves table: the reading carries problems: ($problems | str join '; ')" } }
    let order = (if ($builds | is-empty) { $c.builds | get build } else { $builds })
    let ms = {|us| if $us == null { "-" } else { ($us / 1000) | math round --precision 1 | into string } }
    let cell = {|l| if $l == null or $l.mean == null { "-" } else { $"(do $ms $l.mean) +/-(do $ms $l.half) [(do $ms $l.run_least)-(do $ms $l.run_most)]" } }
    let legs = ($c.builds | get 0.legs | get leg)
    let head = $"| leg | ($order | str join ' | ') |"
    let rule = $"|---|($order | each {|_| '---' } | str join '|')|"
    let rows = ($legs | each {|leg| $"| ($leg) | ($order | each {|b| do $cell ($c.builds | where build == $b | get 0.legs | where leg == $leg | get -o 0) } | str join ' | ') |" })
    let whole = $"| whole | ($order | each {|b| do $cell ($c.builds | where build == $b | get 0.whole) } | str join ' | ') |"
    let over = $"| over 15 ms | ($order | each {|b| let w = ($c.builds | where build == $b | get 0.whole); $'($w.over) of ($w.frames)' } | str join ' | ') |"
    [$head $rule] ++ $rows ++ [$whole $over] | str join "\n"
}

def main [mode: string, base: string, out: string, ...labels: string] {
    let c = (curves $mode $base $labels)
    $c | to nuon --indent 1 | save --raw -f $out
    print $"gaincurves ($mode): ($c.builds | length) builds, ($c.problems | length) problems, identities alike ($c.identities_alike); ($out)"
}

def "main table" [reading: string, ...builds: string] {
    table-of (open $reading) $builds | print
}

# The reader's own fixtures over synthetic batches batches.nu writes under
# `scratch`, through the entry points the recipes reach, each case named
# so a raise fails it by name: a clean battery read by `main` and its
# reading tabled; a battery holding an invalid run and one holding a forced
# run drawn by other workers than it asked, each refused by `curves`
# naming its problem; and a reading carrying a problem refused by `table`
# naming it.
def "main holds" [scratch: string] {
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    mkdir $scratch
    let fail = {|name: string, why: string| error make { msg: $"gaincurves holds: ($name): ($why)" } }
    let named = {|name: string, work: closure| try { do $work } catch {|e| do $fail $name $"raised: ($e.msg | str substring 0..300)" } }
    let refused = {|name: string, work: closure, says: string|
        let why = (try { do $work | ignore; null } catch {|e| $e.msg })
        if $why == null { do $fail $name "accepted" }
        if not ($why | str contains $says) { do $fail $name $"refused for ($why | str substring 0..300)" }
    }
    let forced = { build: { image_sha256: "holds_image" }, mode: { cadence: 0, workers: 2, grain: 0 } }
    let two = [[2 0] [2 0] [2 0]]
    let run_of = {|drawn: list<any>| { identity: $forced, cadence: 0, drawn: $drawn } }

    # a clean battery read by main, its reading tabled
    let clean = ($scratch | path join "clean")
    write-batch $clean "clean_1" $forced [(do $run_of $two) (do $run_of $two)] | ignore
    let read = ($scratch | path join "clean.nuon")
    do $named "a clean battery read" { main play $clean $read clean_1 }
    let tabled = (do $named "a clean reading tabled" { table-of (open $read) [] })
    if not (($tabled | str contains "| walk |") and ($tabled | str contains "| whole |")) { do $fail "a clean reading tabled by leg and whole" $tabled }

    # a battery holding an invalid run, refused by curves by name
    let invalid = ($scratch | path join "invalid")
    let file = (write-batch $invalid "invalid_1" $forced [(do $run_of $two) (do $run_of $two)])
    let g = (open $file)
    let runs = ($g.runs | enumerate | each {|x| if $x.index == 0 { $x.item | update measured.valid false } else { $x.item } })
    $g | update runs $runs | to nuon | save --raw -f $file
    do $refused "a battery with an invalid run is refused by curves" { curves "play" $invalid [invalid_1] } "invalid_1 run 1: complete true, valid false, seeded true"

    # a battery holding a forced run drawn by other workers, refused by name
    let other = ($scratch | path join "other")
    write-batch $other "other_1" $forced [(do $run_of [[1 0] [1 0] [1 0]])] | ignore
    do $refused "a battery with a forced run drawn by other workers is refused by curves" { curves "play" $other [other_1] } "other_1 run 1: workers [1] at grains [0] where 2 at 0 was asked"

    # a reading carrying a problem, refused by table by name
    let planted = (open $read | update problems ["a planted problem"])
    do $refused "a reading carrying problems is refused by table" { table-of $planted [] } "a planted problem"
    print "gaincurves holds: ok"
}
