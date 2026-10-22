# The pose fields a reading takes from the pose set, never from its capture
export const READING_FIELDS = [witness derivative]

# A level's verdict against a reference level and its band
def judged [level: int, reference: int, band: any]: nothing -> string {
    let least = (if $band == null { $reference } else { $band - 1 })
    let most = (if $band == null { $reference } else { $band })
    if $level < $least { "sharper" } else if $level > $most { "coarser" } else { "agree" }
}

# A pose's judged blocks read one by one, by both references
def blocks-of [rows: path]: nothing -> record {
    let read = (open $rows | where {|r| ($r | get -o class | default "judged") == "judged" and ($r.levels | get 0) != null and ($r.levels | get 1) != null } | each {|r|
        let today = ($r.levels | get 0)
        let cand = ($r.levels | get 1)
        {
            today: (judged $today $r.reference $r.band), candidate: (judged $cand $r.reference $r.band),
            today_secant: (judged $today $r.secant_reference $r.secant_band), candidate_secant: (judged $cand $r.secant_reference $r.secant_band),
            along_decides: ($r.along >= $r.down), ratio: (if $r.along > 0 { $r.secant / $r.along } else { null }), differ: ($today != $cand),
        }
    })
    let along = {|who: string|
        let off = ($read | where {|b| ($b | get $who) != "agree" and ($b | get $"($who)_secant") == "agree" })
        let ratios = ($off | get ratio | compact)
        { blocks: ($off | length), along_decides: ($off | where along_decides | length), ratio: (if ($ratios | is-empty) { null } else { [($ratios | math min) ($ratios | math max)] }) }
    }
    {
        levels_differ: ($read | where differ | length),
        shared_sharper: ($read | where {|b| $b.today == "sharper" and $b.candidate == "sharper" } | length),
        own_sharper: ($read | where {|b| $b.candidate == "sharper" and $b.today != "sharper" } | length),
        new_off: ($read | where {|b| $b.today == "agree" and $b.candidate != "agree" } | length),
        today_own_sharper: ($read | where {|b| $b.today == "sharper" and $b.candidate != "sharper" } | length),
        along_today: (do $along today),
        along_candidate: (do $along candidate),
    }
}

# A view's verdict by one reference: the candidate's disagreements
def verdict-of [today: record, cand: record, prefix: string]: nothing -> record {
    let field = {|t: record, name: string| $t | get $"($prefix)($name)" }
    let today_off = ((do $field $today sharper) + (do $field $today coarser))
    let cand_off = ((do $field $cand sharper) + (do $field $cand coarser))
    { today: $today_off, candidate: $cand_off, candidate_sharper: (do $field $cand sharper), holds: ($cand_off <= $today_off and (do $field $cand sharper) == 0) }
}

# A view's no-new-departure check against the declared reference, by its blocks
def departure-of [b: record]: nothing -> record<new_off: int, own_sharper: int, holds: bool> {
    { new_off: $b.new_off, own_sharper: $b.own_sharper, holds: ($b.new_off == 0 and $b.own_sharper == 0) }
}

# A view's population held: resolved, judged, its actors and its witnesses
def population-of [c: record, rows: path, listed: record]: nothing -> record<counts: record, problems: list<string>> {
    let pop = $c.reference.population
    let unresolved = ($pop.classes | transpose class blocks | where {|x| $x.class not-in [judged sky] and $x.blocks > 0 } | each {|x| $"($x.blocks) blocks unresolved, ($x.class)" })
    let none = (if $pop.classes.judged == 0 { ["no block judged"] } else { [] })
    let actors = (if ($c.pose | get -o hold | default false) and $pop.actors == 0 { ["no actor's block judged"] } else { [] })
    let witness = ($listed | get -o witness)
    let derivative = ($listed | get -o derivative)
    let table = (if $witness == null and $derivative == null { [] } else { open $rows })
    let at = {|w: record| $table | where {|r| $r.row == $w.row and $r.x0 == $w.x0 } | get -o 0 }
    let clamp = (if $witness == null { [] } else {
        let found = (do $at $witness)
        if $pop.clamped == 0 {
            ["no clamped block judged"]
        } else if $found == null or $found.class != "judged" or (not $found.clamped) {
            [$"the witness at row ($witness.row) and ($witness.x0) is no clamped block judged"]
        } else if (judged ($found.levels | get 1) $found.secant_reference $found.secant_band) != "agree" {
            [$"the candidate's level at the witness, ($found.levels | get 1), is not the clamped reference's ($found.secant_reference)"]
        } else { [] }
    })
    let down = (if $derivative == null { [] } else {
        let found = (do $at $derivative)
        if $found == null or $found.class != "judged" or (not $found.clamped) {
            [$"the derivative witness at row ($derivative.row) and ($derivative.x0) is no clamped block judged"]
        } else if $found.down != $derivative.down {
            [$"the down term at the derivative witness, ($found.down), is not the recorded ($derivative.down)"]
        } else { [] }
    })
    { counts: $pop, problems: ($unresolved ++ $none ++ $actors ++ $clamp ++ $down) }
}

# Every captured pose judged against the pose set, reading.nuon written
export def read [out: path, poses: path]: nothing -> nothing {
    let set = (open $poses)
    let inventory = ($set | get name)
    let captured = (glob ($out | path join "*" "pose.nuon") | sort | each {|f| open $f })
    if ($captured | is-empty) { error make { msg: $"no pose captured in ($out)" } }
    let missing = ($inventory | where {|n| $n not-in ($captured | get pose.name) })
    let refused = ($captured | where {|c| not ($c.problems | is-empty) } | each {|c| { pose: $c.pose.name, problems: $c.problems } })
    let views = ($captured | where {|c| $c.problems | is-empty } | each {|c|
        let today = ($c.reference.captures | get 0)
        let cand = ($c.reference.captures | get 1)
        let rows = ($out | path join $c.pose.name "rows.nuon")
        let blocks = (blocks-of $rows)
        let population = (population-of $c $rows ($set | where name == $c.pose.name | get -o 0 | default {}))
        {
            pose: $c.pose.name, map: $c.pose.map, judged: $today.judged, sensitive: $population.counts.sensitive, clamped: $population.counts.clamped,
            iz_min: ($c.reference | get -o iz_min), floor_depth: ($c.reference | get -o floor_depth),
            population: $population.counts, resolved: ($population.problems | is-empty), unresolved: $population.problems,
            declared: (verdict-of $today $cand ""), secant: (verdict-of $today $cand "secant_"),
            departure: (departure-of $blocks),
            blocks: $blocks,
            today_levels: $today.levels, candidate_levels: $cand.levels,
            pictures: (if $c.pictures == null { null } else { { pixels: $c.pictures.pixels, regions: ($c.pictures.regions | length), largest: ($c.pictures.regions | get -o largest | default [] | append 0 | math max) } }),
        }
    })
    let whole = (($views | length) > 0 and ($refused | is-empty) and ($missing | is-empty) and ($views | all {|v| $v.resolved }))
    let declared = ($whole and ($views | all {|v| $v.declared.holds }))
    let secant = ($whole and ($views | all {|v| $v.secant.holds }))
    let departures = ($whole and ($views | all {|v| $v.departure.holds }))
    let revised = ($secant and $departures)
    let own = ($views | reduce --fold 0 {|v, acc| $acc + $v.blocks.own_sharper })
    for v in $views {
        let b = $v.blocks
        let pictures = (if $v.pictures == null { "no pictures" } else { $"the pictures ($v.pictures.pixels) pixels in ($v.pictures.regions) regions, at most ($v.pictures.largest) apart" })
        let floor = (if $v.iz_min == null { "its floor unrecorded" } else { $"at IZ_MIN ($v.iz_min), ($v.floor_depth | math round --precision 1) m deep" })
        print $"($v.pose): ($v.population.blocks) blocks, ($v.judged) judged, ($v.sensitive) in a band, ($v.clamped) clamped ($floor), ($v.population.actors) on actors; (if $v.resolved { 'every block accounted for' } else { $v.unresolved | str join '; ' })"
        print $"  declared today ($v.declared.today) off, the candidate ($v.declared.candidate) with ($v.declared.candidate_sharper) sharper, (if $v.declared.holds { 'holds' } else { 'fails' }); secant today ($v.secant.today), the candidate ($v.secant.candidate) with ($v.secant.candidate_sharper) sharper, (if $v.secant.holds { 'holds' } else { 'fails' }); ($pictures)"
        print $"  blocks: levels differing in ($b.levels_differ); sharper for both ($b.shared_sharper), the candidate's own ($b.own_sharper), today's own ($b.today_own_sharper); the along step's, today ($b.along_today.blocks) and the candidate ($b.along_candidate.blocks), the along term deciding in ($b.along_candidate.along_decides) of the candidate's, its step over the start's derivative ($b.along_candidate.ratio | default [] | each {|x| $x | math round --precision 3 } | str join ' to ')"
        print $"  no new departure from the declared reference: ($v.departure.new_off) blocks off it where today's agrees, ($v.departure.own_sharper) sharper where today's is not, (if $v.departure.holds { 'holds' } else { 'fails' })"
    }
    for r in $refused { print $"($r.pose): refused, ($r.problems | str join '; ')" }
    for m in $missing { print $"($m): missing, the pose set's but never captured" }
    { views: $views, refused: $refused, missing: $missing, whole: $whole, declared_holds: $declared, secant_holds: $secant, departures_hold: $departures, revised_holds: $revised, own_sharper: $own } | to nuon --indent 2 | save --raw -f ($out | path join "reading.nuon")
    print $"footprint read: ($views | length) views, ($refused | length) refused, ($missing | length) missing; (if $whole { 'every view accounted for' } else { 'incomplete: a view refused, missing, or unresolved' }); the declared criteria (if $declared { 'hold' } else { 'fail' }), as recorded; the revised criterion (if $revised { 'holds' } else { 'fails' }), the secant's verdicts (if $secant { 'holding' } else { 'failing' }) and no new departure (if $departures { 'holding' } else { 'failing' }); the candidate's own sharper blocks by the declared reference ($own)"
}
