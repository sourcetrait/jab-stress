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
# table in milliseconds.
use ./workergauge.nu [analyse]

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
