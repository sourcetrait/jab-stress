use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../../jab/kit/fierce/nu/mod/picture)
use (path self ../../../../../../jab/kit/fierce/nu/mod/tree)
use (path self ../../workerparity) [disk-of answered-frames]

# The game's directory in jab, checked out beside the workbench
export const GAME = path self ../../../../../../jab/kit/fierce

# Each kind of pose's images: its OWNER, LEVELS, and picture captures'
export const KINDS = {
    view: { owner: owner, levels: [levels levels_candidate], pictures: [picture picture_candidate] }
    clamp: { owner: owner_clamp, levels: [levels_clamp levels_candidate_clamp], pictures: [] }
}

# The console's P as its answer carries it
const CONSOLE_P = 80

# A run's screen bound to the frame it shows, one packet for LEVELS
export def bind [run: record, p: record, levels: bool]: nothing -> record<stamp: any, from: any, frame: any, state: any, problems: list<string>> {
    let placed = (answered-frames $run.api $CONSOLE_P)
    if $run.screen == "" { return { stamp: null, from: ($placed | get -o 1), frame: null, state: null, problems: ["no screen was taken"] } }
    let stamp = (picture stamp (open --raw $run.screen | into binary))
    if ($placed | length) < 2 { return { stamp: $stamp, from: null, frame: null, state: null, problems: [$"the second placement unanswered: ($placed | length) answered"] } }
    let measured = (gauge measure $run.api [{ name: "start", places: [], pad: [] }, { name: "placed", places: [$p $p], pad: [] }])
    let expect = { pose: ($p | select x y z yaw pitch roll), workers: 0, grain: 0, masks: null, witness: null }
    let b = (gauge measure screen-frame $measured $stamp ($placed | get 1) $expect)
    let row = (if $b.frame == null { null } else { $measured.rows | where frame == $b.frame | get -o 0 })
    let flushed = (if $levels and $row != null and $row.flushes != 0 { [$"frame ($b.frame) drawn from ($row.flushes + 1) packets, where a LEVELS frame must be drawn from one"] } else { [] })
    { stamp: $stamp, from: ($placed | get 1), frame: $b.frame, state: (if $row == null { null } else { $row | select x y z yaw pitch roll }), problems: ($b.problems ++ $flushed) }
}

# The game's footprint crate built release: its path, digest, and commit
export def footprint-tool []: nothing -> record<path: string, sha256: string, commit: string, dirty: bool> {
    let manifest = ($GAME | path join "rust" "Cargo.toml")
    let built = (^cargo build --release --quiet --manifest-path $manifest -p footprint | complete)
    if $built.exit_code != 0 { error make { msg: $"building the footprint crate: ($built.stderr)" } }
    let meta = (^cargo metadata --format-version 1 --no-deps --manifest-path $manifest | complete)
    if $meta.exit_code != 0 { error make { msg: $"reading the crate's metadata: ($meta.stderr)" } }
    let tool = ($meta.stdout | from json | get target_directory | path join "release" "footprint")
    let repo = ($GAME | path join .. ..)
    {
        path: $tool,
        sha256: (open --raw $tool | into binary | hash sha256),
        commit: (^git -C $repo rev-parse HEAD | complete | get stdout | str trim),
        dirty: ((^git -C $repo status --porcelain | complete | get stdout | str trim) != ""),
    }
}

# A map's copy, its androids dropped but those kept, compiled to a disk in `dir`
def kept-disk [map: string, keep: list<string>, dir: path]: nothing -> record<name: string, tree: string, disk: string, sha256: string> {
    let src = (open ($GAME | path join "content" "map" $"($map).nuon"))
    let unknown = ($keep | where {|k| ($src.entities | where {|e| $e.class == "android" and $e.name == $k } | is-empty) })
    if not ($unknown | is-empty) { error make { msg: $"($map) holds no android named ($unknown | str join ', ')" } }
    let source = ($src | update entities ($src.entities | where {|e| $e.class != "android" or $e.name in $keep }))
    let name = $"($map)_($keep | str join '_')"
    let tree = (tree variant $source $name [] ($dir | path join "tree") $GAME)
    let disk = ($dir | path join $"($name).romfs")
    let made = (^genromfs -d $tree -f $disk -V "fps" | complete)
    if $made.exit_code != 0 { error make { msg: $"genromfs: ($made.stderr)" } }
    { name: $name, tree: $tree, disk: $disk, sha256: (open --raw $disk | hash sha256) }
}

# A pose's disk, its map's still copy or one keeping its androids, made once
export def disk-for [map: string, keep: list<string>, out: path]: nothing -> record {
    let dir = ($out | path join (if ($keep | is-empty) { $"disk_($map)" } else { $"disk_($map)_($keep | str join '_')" }))
    let record = ($dir | path join "disk.nuon")
    if ($record | path exists) {
        let disk = (open $record)
        let now = (open --raw $disk.disk | hash sha256)
        if $now != $disk.sha256 { error make { msg: $"($disk.disk) has SHA-256 ($now) where its record says ($disk.sha256)" } }
        return $disk
    }
    mkdir $dir
    let disk = (if ($keep | is-empty) { disk-of $map $dir } else { kept-disk $map $keep $dir })
    let made = ($disk | insert map (($disk.tree | path join "map" $"($disk.name).jabfps.map")))
    $made | to nuon --indent 2 | save --raw $record
    $made
}

# The clamp's plan over a captured pose: threshold, clamped blocks, witnesses
export def clamp-plan [dir: path, surface: int, --owner: string = "owner", --levels: string = "levels"]: nothing -> nothing {
    let c = (open ($dir | path join "pose.nuon"))
    let s = ($c.rows | where label == $levels | first | get binding.state)
    let screen = {|label: string| $c.rows | where label == $label | first | get screen }
    let tool = (footprint-tool)
    let r = (^$tool.path clamp-plan $c.disk.map $c.disk.tree $s.x $s.y $s.z $s.yaw $s.pitch $s.roll --owner (do $screen $owner) --levels (do $screen $levels) --surface $surface | complete)
    if $r.exit_code != 0 { error make { msg: $"the clamp's plan at ($c.pose.name): ($r.stderr)" } }
    let plan = ($r.stdout | from nuon | insert pose ($c.pose | select name map x y z yaw pitch roll) | insert tool $tool)
    $plan | to nuon --indent 2 | save --raw -f ($dir | path join "clamp_plan.nuon")
    print $"($c.pose.name): surface ($surface)'s ($plan.blocks) blocks from ($plan.depths.least | math round --precision 2) to ($plan.depths.greatest | math round --precision 2) m; the threshold ($plan.depth) m, IZ_MIN ($plan.iz_min), puts ($plan.share * 100 | math round --precision 1) percent past it; ($plan.clamped) clamped, ($plan.witnesses) witnesses"
    for w in $plan.strongest { print $"  witness: row ($w.row) at ($w.x0), ($w.depth | math round --precision 2) m, held level ($w.held.level), unbranched ($w.unbranched.level), free ($w.free.level), margin ($w.margin | math round --precision 3)" }
    print $"  derivative at row ($plan.derivative.block.row) at ($plan.derivative.block.x0): analytic ($plan.derivative.analytic), its finite difference ($plan.derivative.difference)"
}
