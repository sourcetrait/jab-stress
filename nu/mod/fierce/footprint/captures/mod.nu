use (path self ../../../../../../jab/nu/mod/launch)
use (path self ../../../../../../jab/kit/fierce/nu/mod/pose)
use (path self ../../../../../../jab/kit/fierce/nu/mod/console)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../../jab/kit/fierce/nu/mod/picture)
use (path self ../../../../../../jab/kit/fierce/nu/mod/map)
use (path self ../../../../../../jab/kit/fierce/nu/mod/tree)
use (path self ../builds) [IMAGES]
use (path self ../../workerparity) [disk-of answered-frames]

# The game's directory in jab, checked out beside the workbench
export const GAME = path self ../../../../../../jab/kit/fierce

# Each kind of pose's images: the OWNER capture's, the two LEVELS captures', the pictures'
export const KINDS = {
    view: { owner: owner, levels: [levels levels_candidate], pictures: [picture picture_candidate] }
    clamp: { owner: owner_clamp, levels: [levels_clamp levels_candidate_clamp], pictures: [] }
}

# The console's X, the presented frames' snapshots exported
const CONSOLE_X = "X"

# The console's A, every actor at its spawn state and held there
const CONSOLE_A = "A"

# The console's P as its answer carries it
const CONSOLE_P = 80

# When the stamp goes on, under the picture contract
const STAMP_AT = 200ms

# When the screen is taken, under the picture contract
const SCREEN_AT = 9000ms

# A run's bound in seconds, so its final records land
const SECONDS = 11

# The status of a run its bound ends, jab launch's
const BOUND_STATUS = 124

# A capture's launch condition, recorded with it: the API, a silent sound device
const LAUNCH = { api: true, sound: false, audio: "none" }

# The console's P frame with the pose's roll
def placement [p: record]: nothing -> binary {
    let floats = ([$p.x $p.y $p.z $p.yaw $p.pitch $p.roll] | each {|f| $f | into float })
    [("P" | into binary), 0x[00 00 00], ($floats | each {|f| map float-bytes $f } | bytes collect), (0..<36 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# A console frame of a letter with its fourth byte set, the rest zero
def knob-frame [letter: string, value: int]: nothing -> binary {
    [($letter | into binary), 0x[00 00 00], ($value | into binary | bytes at 0..<1), (0..<59 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# A launch's sends: the picture contract's, the serial W, the X after the screen
def sends-of [p: record]: nothing -> list<any> {
    let hold = (if ($p | get -o hold | default false) { [{ at: $STAMP_AT, bytes: (knob-frame $CONSOLE_A 1) }] } else { [] })
    [
        { at: $STAMP_AT, bytes: (console raise 0 --stamp) }
        { at: $STAMP_AT, bytes: (console workers 0 0) }
        ...$hold
        { at: 1900ms, bytes: (pose command-frame "L") }
        { at: 2000ms, bytes: (placement $p) }
        { at: 8000ms, bytes: (placement $p) }
        { at: $SCREEN_AT, bytes: (pose command-frame $CONSOLE_X) }
        { at: $SCREEN_AT, bytes: (pose command-frame "E") }
    ] | sort-by at
}

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

# The lumel maps a launch's load line says the engine baked, or null
def bake-of [lines: list<string>]: nothing -> any {
    let found = ($lines | parse "fps: lumel maps {maps} baked in {ms} ms: {lumels} lumels, {unmapped} unmapped")
    if ($found | is-empty) { return null }
    let b = ($found | first)
    { maps: ($b.maps | into int), lumels: ($b.lumels | into int), unmapped: ($b.unmapped | into int) }
}

# A launch's row: its label, status, screen, faults, bake, and binding
def row-of [run: record, image: record, p: record]: nothing -> record {
    let lines = ($run.serial | lines)
    {
        label: $image.label, status: $run.status, screen: $run.screen,
        screen_sha256: (if $run.screen != "" { open --raw $run.screen | hash sha256 } else { null }),
        faults: ($lines | where {|l| ($l starts-with "jab: ") and (($l =~ "fault") or ($l =~ "shutdown")) }),
        bake: (bake-of $lines),
        binding: (bind $run $p ("LEVELS" in $image.symbols)),
    }
}

# Each launch whose bake differs from the crate's replication, the folds' ground
def bake-problems [rows: list<any>, reference: record]: nothing -> list<string> {
    let crate = $reference.lumels
    $rows | each {|r|
        if $r.bake == null {
            [$"($r.label): no lumel maps line on its UART"]
        } else if $r.bake.maps != $crate.maps or $r.bake.lumels != $crate.lumels or $r.bake.unmapped != $crate.unmapped {
            [$"($r.label): the engine baked ($r.bake.maps) maps, ($r.bake.lumels) lumels, ($r.bake.unmapped) unmapped, where the crate's bake reads ($crate.maps), ($crate.lumels), ($crate.unmapped)"]
        } else { [] }
    } | flatten
}

# Each pose captured on every image, then referenced and differed
export def capture [export: path, poses: path, out: path, --only: string = ""] {
    let export = ($export | path expand)
    let made = (open ($export | path join $IMAGES))
    let wanted = (if $only == "" { [] } else { $only | split row "," })
    let all = (open $poses)
    let unknown = ($wanted | where {|w| $w not-in ($all | get name) })
    if not ($unknown | is-empty) { error make { msg: $"no pose named ($unknown | str join ', ') in ($poses)" } }
    let chosen = (if ($wanted | is-empty) { $all } else { $all | where {|p| $p.name in $wanted } })
    let tool = (footprint-tool)
    for p in $chosen {
        let dir = ($out | path join $p.name)
        if ($dir | path join "pose.nuon" | path exists) { error make { msg: $"($dir) holds a capture; a pose is captured once into an out" } }
        let kind = ($KINDS | get ($p | get -o images | default "view"))
        let labels = ([$kind.owner] ++ $kind.levels ++ $kind.pictures)
        let used = ($made.images | where {|i| $i.label in $labels })
        let floors = ($used | where {|i| $i.label in ([$kind.owner] ++ $kind.levels) } | get iz_min | uniq)
        if ($floors | length) != 1 { error make { msg: $"($p.name)'s OWNER and LEVELS images were assembled at IZ_MIN ($floors | str join ' and '), where one threshold binds them" } }
        let disk = (disk-for $p.map ($p | get -o keep | default []) $out)
        let rows = ($used | each {|i|
            let run = (with-env { JAB_AUDIO: $LAUNCH.audio } { launch --kernel $i.kernel --image $i.image --out ($dir | path join $i.label) --set $i.set --api --live-sound --disk $disk.disk --serial "fps" --send (sends-of $p) --screen $SCREEN_AT --seconds $SECONDS })
            row-of $run $i $p
        })
        let launched = ($rows | each {|r|
            let own = ($r.binding.problems | each {|x| $"($r.label): ($x)" })
            let status = (if $r.status != $BOUND_STATUS { [$"($r.label): status ($r.status), where the bound's ($BOUND_STATUS) was expected"] } else { [] })
            let faults = ($r.faults | each {|f| $"($r.label): ($f)" })
            $own ++ $status ++ $faults
        } | flatten)
        let row = {|label: string| $rows | where label == $label | first }
        let captured = {|label: string| let r = (do $row $label); ["--export" ($dir | path join $label "api.out") $"($r.binding.frame)"] }
        let reference = (if not ($launched | is-empty) { null } else {
            let s = (do $row ($kind.levels | first) | get binding.state)
            let words = (["--iz-min" $"($floors | first)" "--owner" (do $row $kind.owner | get screen) ...(do $captured $kind.owner)] ++ ($kind.levels | each {|l| ["--levels" (do $row $l | get screen) ...(do $captured $l)] } | flatten))
            let r = (^$tool.path reference $disk.map $disk.tree $s.x $s.y $s.z $s.yaw $s.pitch $s.roll ...$words --rows ($dir | path join "rows.nuon") | complete)
            if $r.exit_code != 0 { error make { msg: $"the reference at ($p.name): ($r.stderr)" } }
            $r.stdout | from nuon
        })
        let problems = ($launched ++ (if $reference == null { [] } else { bake-problems $rows $reference }))
        let pictures = (if not ($problems | is-empty) or ($kind.pictures | is-empty) { null } else {
            let d = (^$tool.path differ (do $row ($kind.pictures | get 0) | get screen) (do $row ($kind.pictures | get 1) | get screen) | complete)
            if $d.exit_code != 0 { error make { msg: $"the pictures at ($p.name): ($d.stderr)" } }
            $d.stdout | from nuon
        })
        { pose: $p, disk: $disk, export: $export, commit: $made.commit, tool: $tool, launch: $LAUNCH, rows: $rows, reference: $reference, pictures: $pictures, problems: $problems } | to nuon --indent 2 | save --raw ($dir | path join "pose.nuon")
        if ($problems | is-empty) {
            let today = ($reference.captures | get 0)
            let cand = ($reference.captures | get 1)
            let pop = $reference.population
            let differ = (if $pictures == null { "no pictures" } else { $"the pictures differ in ($pictures.pixels) pixels, ($pictures.regions | length) regions" })
            print $"($p.name): ($pop.blocks) blocks, ($pop.classes.judged) judged, ($pop.unresolved) unresolved, ($pop.sensitive) in a band, ($pop.clamped) clamped, ($pop.actors) on actors; today ($today.sharper) sharper ($today.coarser) coarser, the candidate ($cand.sharper) sharper ($cand.coarser) coarser; by the secant today ($today.secant_sharper) and ($today.secant_coarser), the candidate ($cand.secant_sharper) and ($cand.secant_coarser); ($differ)"
        } else {
            print $"($p.name): refused, ($problems | str join '; ')"
        }
    }
}

# The clamp's plan over a captured pose: its threshold, clamped blocks, witnesses
export def clamp-plan [dir: path, surface: int, --owner: string = "owner", --levels: string = "levels"] {
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
