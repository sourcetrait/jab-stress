# manifest.nu: Qualification's stress manifest (FrameCeiling.md's
# Qualification). Every declarative mutant set the data checkout holds
# under `assets/*/mutants/`, by its path, bytes, and SHA-256 read from its
# raw bytes, with its runner, the root its files are relative to, and its
# whole selection, every mutant by name and their count; every find
# applied in its mutant's order, each required to match exactly once in
# the text its runner mutates as the earlier edits of that mutant left it;
# and every executable harness this workbench holds, `runners/` whole and
# every `*mutants.nu`, by path, bytes, and SHA-256; with the three
# checkouts' commits. A set no runner here names, and a find matching
# other than once, refuse the manifest, every one named. Run under the
# real nu: `nu manifest.nu <jab> <data> <out.nuon>`, the workbench this
# file's own repository.

# the workbench, this file's repository
const STRESS = (path self | path dirname | path join ..)

# Each set's runner, by the set's path under the data checkout's assets:
# the runner, the harness that runs it, and how a mutant names the file
# it mutates: `edit` a file an edit, relative to `root`; `mutant` a file a
# mutant, under `root`; `fixed` one file, `root` itself, for every mutant;
# `walk` a file an edit, relative to the workbench for a reader mutant and
# to jab for a program mutant.
def runners-of [jab: string, stress: string]: nothing -> table {
    let checkout = { runner: "checkout", harness: "runners/checkout_mutants.nuon", shape: "edit", root: $jab }
    let program = { runner: "program", harness: "runners/program_mutants.nuon", shape: "mutant", root: ($jab | path join "game" "fps" "src") }
    let readers = ($stress | path join "fps" "readers")
    ([
        "sdk/mutants/demand_mutants.nuon" "sdk/mutants/launch_mutants.nuon" "sdk/mutants/probe_mutants.nuon"
        "kernel/mutants/compute_mutants.nuon" "kernel/mutants/feature_mutants.nuon" "kernel/mutants/flipreceipt_mutants.nuon"
        "kernel/mutants/jobs_mutants.nuon" "kernel/mutants/loopreorder_mutants.nuon" "kernel/mutants/measure_mutants.nuon"
        "kernel/mutants/minimums_mutants.nuon" "kernel/mutants/order_mutants.nuon" "kernel/mutants/reservation_mutants.nuon"
        "kernel/mutants/spectable_mutants.nuon" "kernel/mutants/stuck_mutants.nuon" "kernel/mutants/submitwait_mutants.nuon"
        "kernel/mutants/worker_mutants.nuon" "fps/mutants/footprint_mutants.nuon"
    ] | each {|p| $checkout | insert set $p }) ++ ([
        "fps/mutants/builder_mutants.nuon" "fps/mutants/cadence_mutants.nuon" "fps/mutants/eviction_mutants.nuon"
        "fps/mutants/handoff_mutants.nuon" "fps/mutants/handoff_set_mutants.nuon" "fps/mutants/interval_mutants.nuon"
        "fps/mutants/packet_mutants.nuon" "fps/mutants/pool_mutants.nuon" "fps/mutants/worker_mutants.nuon"
    ] | each {|p| $program | insert set $p }) ++ [
        { set: "fps/mutants/census_mutants.nuon", runner: "program_reasons", harness: "runners/program_mutants_reasons.nuon", shape: "mutant", root: ($jab | path join "game" "fps" "src") }
        { set: "fps/mutants/census_reader_mutants.nuon", runner: "census_reader", harness: "runners/census_reader_mutants.nuon", shape: "fixed", root: ($jab | path join "game" "fps" "test" "census.nu") }
        { set: "fps/mutants/gauge_mutants.nuon", runner: "gauge", harness: "runners/gauge_mutants.nuon", shape: "fixed", root: ($jab | path join "game" "fps" "test" "gauge.nu") }
        { set: "fps/mutants/poolreader_mutants.nuon", runner: "poolreader", harness: "runners/poolreader_mutants.nuon", shape: "mutant", root: $readers }
        { set: "fps/mutants/tilecensus_mutants.nuon", runner: "tilecensus_reader", harness: "runners/tilecensus_reader_mutants.nuon", shape: "mutant", root: $readers }
        { set: "fps/mutants/workergauge_mutants.nuon", runner: "reader_holds", harness: "runners/reader_holds_mutants.nuon", shape: "mutant", root: $readers }
        { set: "kernel/mutants/selector_mutants.nuon", runner: "selector", harness: "kernel/timing/mutants.nu", shape: "edit", root: $stress }
        { set: "kernel/mutants/walk_mutants.nuon", runner: "walk", harness: "kernel/walk/mutants.nu", shape: "walk", root: $stress }
        { set: "workbench/mutants/provenance_mutants.nuon", runner: "provenance", harness: "runners/program_mutants_cases/provenance_mutants.nu", shape: "fixed", root: ($stress | path join "runners" "provenance.nu") }
    ]
}

# A mutant's edits, each its file's path and its find and put, by the
# set's shape.
def edits-of [m: record, r: record, jab: string]: nothing -> list<record<file: string, find: string, put: string>> {
    let own = (if ($m | get -o edits) == null { [{ find: $m.find, put: $m.put }] } else { $m.edits })
    match $r.shape {
        "edit" => ($own | each {|e| { file: ($r.root | path join $e.file), find: $e.find, put: $e.put } }),
        "mutant" => ($own | each {|e| { file: ($r.root | path join $m.file), find: $e.find, put: $e.put } }),
        "fixed" => ($own | each {|e| { file: $r.root, find: $e.find, put: $e.put } }),
        "walk" => {
            let root = (if $m.kind == "program" { $jab } else { $r.root })
            $own | each {|e| { file: ($root | path join $e.file), find: $e.find, put: $e.put } }
        },
        _ => { error make { msg: $"($r.set): a shape the manifest does not know, ($r.shape)" } },
    }
}

# A file's place in a checkout as the manifest records it: its path,
# bytes, and SHA-256 from its raw bytes.
def held [root: string, file: string]: nothing -> record<path: string, bytes: int, sha256: string> {
    let raw = (open --raw $file | into binary)
    { path: ($file | path relative-to $root), bytes: ($raw | bytes length), sha256: ($raw | hash sha256) }
}

# A runner's root as the manifest records it, its checkout's name before
# its path there: `jab/game/fps/src`, `stress/fps/readers`.
def place-of [root: string, jab: string, stress: string]: nothing -> string {
    let under = {|base: string| ($root | path split | first ($base | path split | length)) == ($base | path split) }
    if (do $under $jab) { "jab" | path join ($root | path relative-to $jab) } else { "stress" | path join ($root | path relative-to $stress) }
}

# A checkout's commit and whether its tree held changes.
def commit-of [repo: string]: nothing -> record<commit: string, dirty: bool> {
    {
        commit: (^git -C $repo rev-parse HEAD | complete | get stdout | str trim),
        dirty: ((^git -C $repo status --porcelain | complete | get stdout | str trim) != ""),
    }
}

# Every mutant of a set applied: each edit's find counted in its file's
# text as the mutant's earlier edits left it, then put in its place; every
# find matching other than once returned as a problem.
def finds-of [set: string, mutants: list<any>, r: record, jab: string]: nothing -> record<checked: int, problems: list<string>> {
    mut checked = 0
    mut problems = []
    for m in $mutants {
        mut texts = {}
        for e in (edits-of $m $r $jab) {
            if not ($e.file | path exists) {
                $problems = ($problems | append $"($set) ($m.name): its file ($e.file) does not exist")
                continue
            }
            let text = (if $e.file in ($texts | columns) { $texts | get $e.file } else { open --raw $e.file | decode })
            let matches = (($text | split row $e.find | length) - 1)
            $checked += 1
            if $matches != 1 {
                $problems = ($problems | append $"($set) ($m.name): a find matches ($matches) times in ($e.file)")
                continue
            }
            $texts = ($texts | upsert $e.file ($text | str replace $e.find $e.put))
        }
    }
    { checked: $checked, problems: $problems }
}

# The data checkout's sets read against the runners: each set as the
# manifest records it, the finds checked, and every problem, the manifest
# refused unless there are none.
def scan [jab: string, data: string, stress: string]: nothing -> record<sets: list<any>, checked: int, problems: list<string>> {
    let assets = ($data | path join "assets")
    let known = (runners-of $jab $stress)
    let files = (glob ($assets | path join "*" "mutants" "*.nuon") | sort)
    let unnamed = ($files | each {|f| $f | path relative-to $assets } | where {|p| $p not-in ($known | get set) })
    let absent = ($known | get set | where {|p| not ($assets | path join $p | path exists) })
    mut problems = ($unnamed | each {|p| $"($p): a set no runner here names" }) ++ ($absent | each {|p| $"($p): a set the manifest names that the data checkout lacks" })
    mut sets = []
    mut checked = 0
    for f in $files {
        let rel = ($f | path relative-to $assets)
        let r = ($known | where set == $rel | get -o 0)
        if $r == null { continue }
        let mutants = (open --raw $f | decode | from nuon)
        let names = ($mutants | get name)
        if ($names | uniq | length) != ($names | length) { $problems = ($problems | append $"($rel): a mutant name repeated") }
        let found = (finds-of $rel $mutants $r $jab)
        $checked += $found.checked
        $problems = ($problems | append $found.problems)
        let root = (if $r.shape == "walk" { "stress, jab for a program mutant" } else { place-of $r.root $jab $stress })
        $sets = ($sets | append ((held $data $f) | merge { runner: $r.runner, harness: $r.harness, shape: $r.shape, root: $root, mutants: $names, count: ($names | length) }))
    }
    { sets: $sets, checked: $checked, problems: $problems }
}

def main [jab: path, data: path, out: path] {
    let jab = ($jab | path expand)
    let data = ($data | path expand)
    let stress = ($STRESS | path expand)
    let scanned = (scan $jab $data $stress)
    if not ($scanned.problems | is-empty) {
        error make { msg: $"the manifest refused, ($scanned.problems | length) problems:\n($scanned.problems | str join (char nl))" }
    }
    let sets = $scanned.sets
    let checked = $scanned.checked
    let harness_files = ((glob ($stress | path join "runners" "**" "*") | where {|p| ($p | path type) == "file" }) ++ (glob ($stress | path join "**" "*mutants.nu")) | uniq | sort)
    let manifest = {
        generated: (date now | format date "%Y-%m-%dT%H:%M:%SZ"),
        commits: { jab: (commit-of $jab), stress: (commit-of $stress), data: (commit-of $data) },
        sets: $sets,
        mutants: ($sets | get count | math sum),
        finds: $checked,
        harnesses: ($harness_files | each {|h| held $stress $h }),
    }
    $manifest | to nuon --indent 2 | save --raw $out
    print $"manifest: ($sets | length) sets, ($manifest.mutants) mutants, ($checked) finds each matching once, ($manifest.harnesses | length) harnesses; ($out)"
}

# The scan's own fixtures on mirrors of the data checkout's sets under
# `scratch`, which the call makes: the mirror as it is, every set read and
# nothing refused; a mutant whose second edit finds the text its first
# wrote, nothing refused, since a mutant's edits apply in order; then one
# alteration a mirror, each refused for it alone, by name: a find matching
# nowhere, a find matching twice, a set no runner names, and a named set
# gone.
def "main holds" [jab: path, data: path, scratch: path] {
    use std/assert
    if ($scratch | path exists) { error make { msg: $"the scratch exists: ($scratch)" } }
    let jab = ($jab | path expand)
    let data = ($data | path expand)
    let stress = ($STRESS | path expand)
    let sets = (glob ($data | path join "assets" "*" "mutants" "*.nuon") | each {|f| $f | path relative-to ($data | path join "assets") })
    let mirror = {|name: string|
        let root = ($scratch | path join $name)
        for s in $sets {
            let to = ($root | path join "assets" $s)
            mkdir ($to | path dirname)
            cp ($data | path join "assets" $s) $to
        }
        $root
    }
    let footprint = "fps/mutants/footprint_mutants.nuon"
    let refind = {|root: string, find: string|
        let file = ($root | path join "assets" $footprint)
        let rows = (open --raw $file | decode | from nuon)
        let first = ($rows | first)
        let edits = ($first.edits | enumerate | each {|e| if $e.index == 0 { $e.item | update find $find } else { $e.item } })
        $rows | enumerate | each {|r| if $r.index == 0 { $r.item | update edits $edits } else { $r.item } } | to nuon | save --raw -f $file
        $first.name
    }
    let control = (scan $jab (do $mirror "control") $stress)
    assert equal $control.problems [] "the mirror as it is: nothing refused"
    assert equal ($control.sets | length) ($sets | length) "the mirror as it is: every set read"
    let ordered = (do $mirror "ordered")
    let file = ($ordered | path join "assets" $footprint)
    let rows = (open --raw $file | decode | from nuon)
    let first = ($rows | first)
    let e = ($first.edits | first)
    let marker = "    # a line the mutant's next edit finds\n"
    let edits = [($e | update put ($e.put + $marker)), { file: $e.file, find: $marker, put: "" }]
    $rows | enumerate | each {|r| if $r.index == 0 { $r.item | update edits $edits } else { $r.item } } | to nuon | save --raw -f $file
    let read = (scan $jab $ordered $stress)
    assert equal $read.problems [] "a mutant's second edit finding the text its first wrote, applied in order: nothing refused"
    let nowhere = (do $mirror "nowhere")
    let name = (do $refind $nowhere "a text matching nowhere in the file")
    let render = ($jab | path join "game" "fps" "src" "render.inc")
    let read = (scan $jab $nowhere $stress)
    assert equal $read.problems [$"($footprint) ($name): a find matches 0 times in ($render)"] "a find matching nowhere refused for it alone"
    let twice = (do $mirror "twice")
    do $refind $twice "    srai \\s2, \\dst, 63\n" | ignore
    let read = (scan $jab $twice $stress)
    assert equal $read.problems [$"($footprint) ($name): a find matches 2 times in ($render)"] "a find matching twice refused for it alone"
    let stray = (do $mirror "stray")
    cp ($stray | path join "assets" $footprint) ($stray | path join "assets" "fps" "mutants" "stray_mutants.nuon")
    let read = (scan $jab $stray $stress)
    assert equal $read.problems ["fps/mutants/stray_mutants.nuon: a set no runner here names"] "a set no runner names refused for it alone"
    let gone = (do $mirror "gone")
    rm ($gone | path join "assets" "kernel" "mutants" "order_mutants.nuon")
    let read = (scan $jab $gone $stress)
    assert equal $read.problems ["kernel/mutants/order_mutants.nuon: a set the manifest names that the data checkout lacks"] "a named set gone refused for it alone"
    print $"manifest holds: ok, ($control.sets | length) sets read on the control and each of four alterations refused for itself alone"
}
