use (path self ../../../../../jab/nu/mod/target)
use (path self ../../../../../jab/nu/mod/build)
use (path self ../../../../../jab/nu/mod/launch)
use (path self ../../../../../jab/kit/fierce/nu/mod/pose)
use (path self ../../../../../jab/kit/fierce/nu/mod/console)
use (path self ../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../jab/kit/fierce/nu/mod/picture)
use (path self ../../../../../jab/kit/fierce/nu/mod/map)
use (path self ../../../../../jab/kit/fierce/nu/mod/tree)
use (path self ../freeze) [symbols-of provenance-of]
use (path self ../workerparity) [disk-of answered-frames]

# The game's directory in jab, checked out beside the workbench
const GAME = path self ../../../../../jab/kit/fierce

# The images an export is built as, each a label, its set, and the poses' kind it serves
const BUILDS = [
    [label, set, kind];
    [picture, "debug", view]
    [picture_candidate, "debug,footprint", view]
    [owner, "debug,owner", view]
    [levels, "debug,levels", view]
    [levels_candidate, "debug,footprint,levels", view]
    [owner_clamp, "debug,iz_test,owner", clamp]
    [levels_clamp, "debug,iz_test,levels", clamp]
    [levels_candidate_clamp, "debug,footprint,iz_test,levels", clamp]
]

# Each kind of pose's images: the OWNER capture's, the two LEVELS captures', the pictures'
const KINDS = {
    view: { owner: owner, levels: [levels levels_candidate], pictures: [picture picture_candidate] }
    clamp: { owner: owner_clamp, levels: [levels_clamp levels_candidate_clamp], pictures: [] }
}

# The console's X, the presented frames' snapshots exported
const CONSOLE_X = "X"

# The console's A, every actor at its spawn state and held there
const CONSOLE_A = "A"

# The images' record, in the export's own directory
const IMAGES = "footprint_images.nuon"

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

# A capture's launch condition, recorded with it: the API on, no sound recorded
const LAUNCH = { api: true, sound: false }

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
def bind [run: record, p: record, levels: bool]: nothing -> record<stamp: any, from: any, frame: any, state: any, problems: list<string>> {
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
def footprint-tool []: nothing -> record<path: string, sha256: string, commit: string, dirty: bool> {
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

# The 1/z floor an image was assembled with: its ELF's IZ_MIN, an integer in 6.26
def iz-min-of [elf: path, prefix: string]: nothing -> int {
    let listed = (^$"($prefix)nm" $elf | complete)
    if $listed.exit_code != 0 { error make { msg: $"nm of ($elf): ($listed.stderr)" } }
    let found = ($listed.stdout | lines | parse "{value} {type} {name}" | where name == "IZ_MIN")
    if ($found | length) != 1 { error make { msg: $"($elf) carries ($found | length) IZ_MIN symbols, where an image carries one" } }
    $"0x($found | first | get value)" | into int
}

# The export's program directory, the one holding a manifest
def program-of [export: path]: nothing -> string {
    let manifests = (glob ($export | path join "**" "program.jab.toml"))
    if ($manifests | length) != 1 { error make { msg: $"($export) holds ($manifests | length) program manifests, where an export holds one" } }
    $manifests | first | path dirname
}

# An export's five debug images built with their kernels and provenance
export def images [export: path] {
    let export = ($export | path expand)
    let record = ($export | path join $IMAGES)
    if ($record | path exists) { error make { msg: $"($record) exists; an export's images are made once" } }
    let program = (program-of $export)
    let source = (open ($program | path join "source.nuon"))
    let repo = (open ($program | path join "program.jab.toml") | get workspace)
    let tool = ($repo | path join "nu" "bin" "do.nu")
    let place = ($program | path relative-to $export)
    mut images = []
    for b in $BUILDS {
        let copy = ($export | path dirname | path join $"($export | path basename)_($b.label)")
        if ($copy | path exists) { error make { msg: $"($copy) exists; an image is built once" } }
        let target = ($copy | path join $place)
        mkdir $target
        for item in [src program.jab.toml source.nuon] { cp -r ($program | path join $item) $target }
        let kernel_built = (^nu $tool build ($repo | path join "kernel") --kernel --set $b.set | complete)
        if $kernel_built.exit_code != 0 { error make { msg: $"the ($b.label) kernel's build: ($kernel_built.stdout + $kernel_built.stderr | lines | last 6 | str join ' | ')" } }
        let built = (^nu $tool build $target --set $b.set | complete)
        if $built.exit_code != 0 { error make { msg: $"the ($b.label) build of ($target): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
        let out = (build program-out $target debug)
        let name = (open ($target | path join "program.jab.toml") | get name)
        let image = ($out | path join $"($name).jab")
        if not ($image | path exists) { error make { msg: $"no ($name).jab at ($out)" } }
        let names = (symbols-of $b.set)
        let flags = (open --raw ($out | path join "flags") | decode | lines | first)
        let missing = ($names | where {|n| not ($flags | str contains $"--defsym ($n)=1") })
        if not ($missing | is-empty) { error make { msg: $"the ($b.label) build's flags lack ($missing | str join ', '): ($flags)" } }
        let kernel = ($out | path join "kernel.elf")
        cp (build program-kernel $target debug) $kernel
        let prefix = ($flags | split row " " | last)
        let bin = ($out | path join "kernel.bin")
        let copied = (^$"($prefix)objcopy" -O binary $kernel $bin | complete)
        if $copied.exit_code != 0 { error make { msg: $"objcopy of ($kernel): ($copied.stderr)" } }
        let provenance = (provenance-of $repo $source.commit $image $names)
        let entry = {
            label: $b.label, set: $b.set, kind: $b.kind, symbols: $names, image: $image, image_sha256: $provenance.image_sha256,
            elf_sha256: $provenance.elf_sha256, iz_min: (iz-min-of ($out | path join $"($name).elf") $prefix),
            kernel: $kernel, kernel_sha256: (open --raw $kernel | into binary | hash sha256),
            kernel_loaded_sha256: (open --raw $bin | into binary | hash sha256), flags: $flags,
        }
        $images = ($images | append $entry)
        print $"($b.label): ($image), SHA-256 ($entry.image_sha256), IZ_MIN ($entry.iz_min), the kernel's loaded bytes ($entry.kernel_loaded_sha256)"
    }
    let loaded = ($images | get kernel_loaded_sha256 | uniq)
    if ($loaded | length) != 1 { error make { msg: $"the images' kernels load different bytes: ($images | select label kernel_loaded_sha256 | to nuon)" } }
    { export: $export, commit: $source.commit, images: $images } | to nuon --indent 2 | save --raw $record
    print $"footprint images: ($images | length) built from ($source.commit), one kernel's code under all"
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
def disk-for [map: string, keep: list<string>, out: path]: nothing -> record {
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
            let run = (launch --kernel $i.kernel --image $i.image --out ($dir | path join $i.label) --set $i.set --api --disk $disk.disk --serial "fps" --send (sends-of $p) --screen $SCREEN_AT --seconds $SECONDS)
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

# The revised criterion as SecantCriterion states it, printed with every reading
const REVISION = "The criterion is revised after the first measurement (SecantCriterion): it now tests whether the candidate's row estimate gives the level a block's footprint asks when the along term is the engine's own step, the secant over the block's true length, and the down term the analytic derivative at the block's start on the mapping the engine uses there; it does not test whether the engine's along stepping matches the analytic derivative (AlongSpanFootprint). The declared criteria's result stands as recorded."

# The clamp's limit as ClampedReference states it, printed with every reading
const LIMIT = "The release threshold, IZ_MIN 4096 in 6.26, a depth of 16,384 m, is not exercised by the inventoried content and poses; the clamp is proved at the test threshold, IZ_TEST's, on the clamp pose (ClampedReference)."

# A view's no-new-departure check against the declared reference, by its blocks
def departure-of [b: record]: nothing -> record<new_off: int, own_sharper: int, holds: bool> {
    { new_off: $b.new_off, own_sharper: $b.own_sharper, holds: ($b.new_off == 0 and $b.own_sharper == 0) }
}

# A view's population held: none unresolved, one judged, its kind's own judged
def population-of [c: record, rows: path]: nothing -> record<counts: record, problems: list<string>> {
    let pop = $c.reference.population
    let unresolved = ($pop.classes | transpose class blocks | where {|x| $x.class not-in [judged sky] and $x.blocks > 0 } | each {|x| $"($x.blocks) blocks unresolved, ($x.class)" })
    let none = (if $pop.classes.judged == 0 { ["no block judged"] } else { [] })
    let actors = (if ($c.pose | get -o hold | default false) and $pop.actors == 0 { ["no actor's block judged"] } else { [] })
    let witness = ($c.pose | get -o witness)
    let clamp = (if $witness == null { [] } else {
        let found = (open $rows | where {|r| $r.row == $witness.row and $r.x0 == $witness.x0 } | get -o 0)
        if $pop.clamped == 0 {
            ["no clamped block judged"]
        } else if $found == null or $found.class != "judged" or (not $found.clamped) {
            [$"the witness at row ($witness.row) and ($witness.x0) is no clamped block judged"]
        } else if (judged ($found.levels | get 1) $found.secant_reference $found.secant_band) != "agree" {
            [$"the candidate's level at the witness, ($found.levels | get 1), is not the clamped reference's ($found.secant_reference)"]
        } else { [] }
    })
    { counts: $pop, problems: ($unresolved ++ $none ++ $actors ++ $clamp) }
}

# Every captured pose judged against the pose set, reading.nuon written
export def read [out: path, poses: path] {
    let inventory = (open $poses | get name)
    let captured = (glob ($out | path join "*" "pose.nuon") | sort | each {|f| open $f })
    if ($captured | is-empty) { error make { msg: $"no pose captured in ($out)" } }
    let missing = ($inventory | where {|n| $n not-in ($captured | get pose.name) })
    let refused = ($captured | where {|c| not ($c.problems | is-empty) } | each {|c| { pose: $c.pose.name, problems: $c.problems } })
    let views = ($captured | where {|c| $c.problems | is-empty } | each {|c|
        let today = ($c.reference.captures | get 0)
        let cand = ($c.reference.captures | get 1)
        let rows = ($out | path join $c.pose.name "rows.nuon")
        let blocks = (blocks-of $rows)
        let population = (population-of $c $rows)
        {
            pose: $c.pose.name, map: $c.pose.map, judged: $today.judged, sensitive: $population.counts.sensitive, clamped: $population.counts.clamped,
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
        print $"($v.pose): ($v.population.blocks) blocks, ($v.judged) judged, ($v.sensitive) in a band, ($v.clamped) clamped, ($v.population.actors) on actors; (if $v.resolved { 'every block accounted for' } else { $v.unresolved | str join '; ' })"
        print $"  declared today ($v.declared.today) off, the candidate ($v.declared.candidate) with ($v.declared.candidate_sharper) sharper, (if $v.declared.holds { 'holds' } else { 'fails' }); secant today ($v.secant.today), the candidate ($v.secant.candidate) with ($v.secant.candidate_sharper) sharper, (if $v.secant.holds { 'holds' } else { 'fails' }); ($pictures)"
        print $"  blocks: levels differing in ($b.levels_differ); sharper for both ($b.shared_sharper), the candidate's own ($b.own_sharper), today's own ($b.today_own_sharper); the along step's, today ($b.along_today.blocks) and the candidate ($b.along_candidate.blocks), the along term deciding in ($b.along_candidate.along_decides) of the candidate's, its step over the start's derivative ($b.along_candidate.ratio | default [] | each {|x| $x | math round --precision 3 } | str join ' to ')"
        print $"  no new departure from the declared reference: ($v.departure.new_off) blocks off it where today's agrees, ($v.departure.own_sharper) sharper where today's is not, (if $v.departure.holds { 'holds' } else { 'fails' })"
    }
    for r in $refused { print $"($r.pose): refused, ($r.problems | str join '; ')" }
    for m in $missing { print $"($m): missing, the pose set's but never captured" }
    { views: $views, refused: $refused, missing: $missing, whole: $whole, declared_holds: $declared, secant_holds: $secant, departures_hold: $departures, revised_holds: $revised, revision: $REVISION, limit: $LIMIT, own_sharper: $own } | to nuon --indent 2 | save --raw -f ($out | path join "reading.nuon")
    print $"footprint read: ($views | length) views, ($refused | length) refused, ($missing | length) missing; (if $whole { 'every view accounted for' } else { 'incomplete: a view refused, missing, or unresolved' }); the declared criteria (if $declared { 'hold' } else { 'fail' }), as recorded; the revised criterion (if $revised { 'holds' } else { 'fails' }), the secant's verdicts (if $secant { 'holding' } else { 'failing' }) and no new departure (if $departures { 'holding' } else { 'failing' }); the candidate's own sharper blocks by the declared reference ($own)"
    print $REVISION
    print $LIMIT
}

# The run a restored tree came from, named by the receipt beside the tree
def restored-run [tree: path]: nothing -> string {
    let receipt = ($tree | path dirname | path join "restoration.nuon")
    if not ($receipt | path exists) { error make { msg: $"($tree) has no restoration.nuon beside it, so it is no restoration's tree" } }
    open $receipt | get run
}

# A capture's file in a restored tree, held to the SHA-256 its capture recorded
def restored-file [tree: path, rel: string, sha: any]: nothing -> record<path: string, problems: list<string>> {
    let at = ($tree | path join $rel)
    if not ($at | path exists) { return { path: $at, problems: [$"($rel) is not in the restoration"] } }
    if $sha != null and (open --raw $at | hash sha256) != $sha { return { path: $at, problems: [$"($rel) has another SHA-256 than its capture recorded"] } }
    { path: $at, problems: [] }
}

# An image's IZ_MIN: the images' record's, else its archived ELF's symbol
def floor-of [tree: path, image: record]: nothing -> int {
    let recorded = ($image | get -o iz_min)
    if $recorded != null { return $recorded }
    let elfs = (glob ($tree | path join "exports" "**" "*.elf") | where {|f| (open --raw $f | hash sha256) == $image.elf_sha256 })
    if ($elfs | is-empty) { error make { msg: $"no ELF of SHA-256 ($image.elf_sha256) in ($tree)'s exports, so ($image.label)'s IZ_MIN is unread" } }
    iz-min-of ($elfs | first) ($image.flags | split row " " | last)
}

# The files of a still copy the crate's reference reads: its map and its images
const REFERENCE_READS = ['\.jabfps\.map$' '\.png$']

# A still copy's files, its tree and its disk, each by its path in the run,
# held to the capture's inventory rows: every one absent, of another
# SHA-256, or not the capture's
def still-differ [base: path, rel: list<string>, rows: list<any>, disk: string]: nothing -> list<record<path: string, how: string>> {
    let files = (glob ($base | path join "tree" "**" "*") --no-dir | append ($base | path join $disk) | where {|f| $f | path exists })
    let built = ($files | each {|f| $rel | append ($f | path relative-to $base | path split) | path join })
    let at = {|p: string| $base | path join ($p | path split | skip ($rel | length) | path join) }
    ($rows | each {|r|
        let file = (do $at $r.path)
        if not ($file | path exists) { { path: $r.path, how: "is absent from the copy made again" } } else {
            let sha = (open --raw $file | hash sha256)
            if $sha != $r.sha256 { { path: $r.path, how: $"is made again at SHA-256 ($sha), the capture's ($r.sha256)" } }
        }
    } | compact) ++ ($built | where {|p| $p not-in ($rows | get path) } | each {|p| { path: $p, how: "is in the copy made again and not the capture's" } })
}

# A still copy remade in `into` with its tile.nuon naming the content where
# the capture's checkout held it, as a tree compiled before jab c804ccb did:
# the map source's place in the checkout at the capture's commit
def remade-still [disk: record, c: record, into: path]: nothing -> record<content: any, problems: list<string>> {
    let jab = ($GAME | path join .. .. | path expand)
    let commit = ($c | get -o tool.commit)
    if $commit == null { return { content: null, problems: ["the capture names no commit of its checkout"] } }
    let listed = (^git -C $jab ls-tree -r --name-only $commit | complete)
    if $listed.exit_code != 0 { return { content: null, problems: [$"the checkout's tree at ($commit): ($listed.stderr | str trim)"] } }
    let wanted = ["content" "map" $"($c.pose.map).nuon"]
    let found = ($listed.stdout | lines | where {|p| ($p | path split | last 3) == $wanted })
    if ($found | length) != 1 { return { content: null, problems: [$"the checkout at ($commit) holds ($found | length) sources of ($c.pose.map), where one names the content"] } }
    let content = ($jab | path join ($found | first | path split | drop 2 | path join))
    if ($into | path exists) { error make { msg: $"($into) exists; a still copy is remade once" } }
    mkdir $into
    cp -r ($disk.disk | path dirname | path join "tree") ($into | path join "tree")
    let tree = ($into | path join ($disk.tree | path relative-to ($disk.disk | path dirname)))
    let tiles = ($tree | path join "tile.nuon")
    open $tiles | each {|t| $t | update source (if $t.source == "" { "" } else { $content | path join $t.source }) } | to nuon | save -f $tiles
    let made = (^genromfs -d $tree -f ($into | path join ($disk.disk | path basename)) -V "fps" | complete)
    if $made.exit_code != 0 { error make { msg: $"genromfs over ($tree): ($made.stderr)" } }
    { content: $content, problems: [] }
}

# A still copy made again, held file by file to the capture's inventory, once
# a copy, `held.nuon` beside it: a file the reference reads that differs is a
# problem, any other a limit. A copy that differs is remade as the capture's
# checkout compiled it, and the copy holds when either is the capture's whole
def still-held [disk: record, out: path, inventory: list<any>, c: record]: nothing -> record<problems: list<string>, limits: list<string>, disk: record> {
    let base = ($disk.disk | path dirname)
    let kept = ($base | path join "held.nuon")
    if ($kept | path exists) { return (open $kept) }
    let rel = ($base | path relative-to $out | path split)
    let name = ($disk.disk | path basename)
    let rows = ($inventory | where {|r| ($r.path | path split | first ($rel | length)) == $rel and ($r.path | path basename) != "disk.nuon" })
    let differ = (still-differ $base $rel $rows $name)
    let reads = {|p: string| $REFERENCE_READS | any {|re| $p =~ $re } }
    let problems = ($differ | where {|d| do $reads $d.path } | each {|d| $"($d.path), which the reference reads, ($d.how)" })
    let into = ($base | path join "remade")
    let remade = (if ($differ | is-empty) { null } else if ($problems | is-empty) { remade-still $disk $c $into } else { { content: null, problems: ["not remade, since a file the reference reads differs"] } })
    let after = (if $remade == null or not ($remade.problems | is-empty) { null } else { still-differ $into $rel $rows $name })
    let remade_sha = (if ($into | path join $name | path exists) { open --raw ($into | path join $name) | hash sha256 } else { null })
    let held = (if $remade == null { $disk.sha256 == $c.disk.sha256 } else { $after != null and ($after | is-empty) and $remade_sha == $c.disk.sha256 })
    let limits = (if $remade == null { [] } else if $held {
        [$"the copy names its sources relative to the content; remade naming them under ($remade.content), as the capture's checkout did, its every file and its disk are the capture's, where ($differ | get path | str join ', ') differ made again"]
    } else {
        ($differ | where {|d| not (do $reads $d.path) } | each {|d| $"($d.path) ($d.how); the reference reads no such file" }) ++ $remade.problems ++ ($after | default [] | each {|d| $"remade, ($d.path) ($d.how)" })
    })
    let result = { problems: $problems, limits: $limits, disk: { first: $c.disk.sha256, again: $disk.sha256, remade: $remade_sha, content: ($remade | get -o content), held: $held } }
    $result | to nuon --indent 2 | save --raw $kept
    $result
}

# One captured pose read again from a restoration: disk, bindings, reference
def reread-pose [tree: path, out: path, inventory: list<any>, images: list<any>, c: record, tool: record]: nothing -> record {
    let name = $c.pose.name
    let kind = ($KINDS | get ($c.pose | get -o images | default "view"))
    let labels = ([$kind.owner] ++ $kind.levels ++ $kind.pictures)
    let dir = ($out | path join $name)
    mkdir $dir
    let disk = (disk-for $c.pose.map ($c.pose | get -o keep | default []) $out)
    let held = (still-held $disk $out $inventory $c)
    let disk_problems = $held.problems
    let launches = ($labels | each {|label|
        let r = ($c.rows | where label == $label | first)
        let screen = (restored-file $tree ($name | path join $label "screen.ppm") $r.screen_sha256)
        let api = (restored-file $tree ($name | path join $label "api.out") null)
        let serial = (restored-file $tree ($name | path join $label "serial.log") null)
        let missing = ($screen.problems ++ $api.problems ++ $serial.problems)
        if not ($missing | is-empty) { return { label: $label, row: $r, api: $api.path, missing: $missing, differences: [] } }
        let image = ($images | where label == $label | first)
        let binding = (bind { api: (open --raw $api.path), screen: $screen.path } $c.pose ("LEVELS" in $image.symbols))
        let faults = (open --raw $serial.path | decode | lines | where {|l| ($l starts-with "jab: ") and (($l =~ "fault") or ($l =~ "shutdown")) })
        let fields = [stamp from frame state]
        let differences = ([
            (if ($binding | select ...$fields) != ($r.binding | select -o ...$fields) { $"($label)'s binding read again as frame ($binding.frame) at stamp ($binding.stamp), recorded as frame ($r.binding.frame) at stamp ($r.binding.stamp)" })
            (if $faults != $r.faults { $"($label)'s UART faults read again differ from those recorded" })
        ] | compact)
        { label: $label, row: ($r | update screen $screen.path), api: $api.path, missing: [], differences: $differences }
    })
    let missing = ($launches | get missing | flatten)
    let limits = ($kind.levels | enumerate | where {|e| ($c.reference | get -o captures | default [] | get -o $e.index | get -o snapshot) == null } | each {|e| $"($e.item): its capture carries no span table, so each block's end is read from its pixels" }) ++ $held.limits
    let reference = (if not (($missing ++ $disk_problems) | is-empty) or $c.reference == null { null } else {
        let launch = {|label: string| $launches | where label == $label | first }
        let exported = {|label: string, has: bool| if $has { ["--export" (do $launch $label | get api) $"(do $launch $label | get row.binding.frame)"] } else { [] } }
        let floors = ($images | where {|i| $i.label in ([$kind.owner] ++ $kind.levels) } | each {|i| floor-of $tree $i } | uniq)
        if ($floors | length) != 1 { error make { msg: $"($name)'s OWNER and LEVELS images were assembled at IZ_MIN ($floors | str join ' and ')" } }
        let s = (do $launch ($kind.levels | first) | get row.binding.state)
        let owner_has = (($c.reference | get -o owner) != null)
        let levels = ($kind.levels | enumerate | each {|e| ["--levels" (do $launch $e.item | get row.screen) ...(do $exported $e.item (($c.reference.captures | get -o $e.index | get -o snapshot) != null))] } | flatten)
        let words = (["--iz-min" $"($floors | first)" "--owner" (do $launch $kind.owner | get row.screen) ...(do $exported $kind.owner $owner_has)] ++ $levels)
        let ran = (^$tool.path reference $disk.map $disk.tree $s.x $s.y $s.z $s.yaw $s.pitch ($s | get -o roll | default 0) ...$words --rows ($dir | path join "rows.nuon") | complete)
        if $ran.exit_code != 0 { { problems: [$"the reference: ($ran.stderr | str trim)"], value: null } } else { { problems: [], value: ($ran.stdout | from nuon) } }
    })
    let rows_sha = (if ($dir | path join "rows.nuon" | path exists) { open --raw ($dir | path join "rows.nuon") | hash sha256 } else { null })
    let recorded_rows = ($inventory | where path == ($name | path join "rows.nuon") | get -o 0.sha256)
    let pictures = (if ($kind.pictures | is-empty) or not ($missing | is-empty) { null } else {
        let pic = {|label: string| $launches | where label == $label | first | get row.screen }
        let d = (^$tool.path differ (do $pic ($kind.pictures | get 0)) (do $pic ($kind.pictures | get 1)) | complete)
        if $d.exit_code != 0 { error make { msg: $"the pictures at ($name): ($d.stderr)" } }
        $d.stdout | from nuon
    })
    let picture_differs = ($c.pictures != null and $pictures != null and (($pictures | select pixels regions) != ($c.pictures | select pixels regions)))
    let problems = ($missing ++ $disk_problems ++ ($reference | get -o problems | default []))
    {
        pose: $c.pose, disk: $disk, export: $c.export, commit: $c.commit, tool: $tool, launch: ($c | get -o launch), rows: ($launches | get row),
        reference: ($reference | get -o value), pictures: $pictures, problems: $problems,
        reread: {
            from: ($tree | path join $name "pose.nuon"), first_tool: $c.tool, differences: ($launches | get differences | flatten), limits: $limits, still: $held.disk,
            rows_sha256: $rows_sha, first_rows_sha256: $recorded_rows, rows_same: ($rows_sha != null and $rows_sha == $recorded_rows),
            pictures_same: (if $pictures == null { null } else { not $picture_differs }),
        },
    } | to nuon --indent 2 | save --raw ($dir | path join "pose.nuon")
    { pose: $name, problems: $problems, differences: ($launches | get differences | flatten), limits: $limits, still: $held.disk, rows_same: ($rows_sha != null and $rows_sha == $recorded_rows), pictures_same: (if $pictures == null { null } else { not $picture_differs }) }
}

# A restored footprint run read again: every pose, its reading, the first's beside it
export def reread [tree: path, out: path] {
    let tree = ($tree | path expand)
    let out = ($out | path expand)
    let run = (restored-run $tree)
    let inventory = (open ($run | path join "inventory.nuon"))
    let images = (open ($tree | path join "images" $IMAGES) | get images)
    let captured = (glob ($tree | path join "*" "pose.nuon") | sort | each {|f| open $f })
    if ($captured | is-empty) { error make { msg: $"no pose captured in ($tree)" } }
    mkdir $out
    let tool = (footprint-tool)
    let poses = ($out | path join "poses.nuon")
    $captured | get pose | to nuon --indent 2 | save --raw $poses
    let read = ($captured | each {|c| reread-pose $tree $out $inventory $images $c $tool })
    for r in $read {
        let rows = (if $r.rows_same { "its block table the first's byte for byte" } else { "its block table another than the first's" })
        let still = (if $r.still.held { "its still copy the capture's" } else { "its still copy not the capture's" })
        print $"($r.pose): (if ($r.problems | is-empty) { 'read again' } else { $r.problems | str join '; ' }); ($rows); ($still); ($r.differences | length) differences from the first reading, ($r.limits | length) limits"
    }
    read $out $poses
    let first = (open ($tree | path join "reading.nuon"))
    let again = (open ($out | path join "reading.nuon"))
    let fields = [judged sensitive clamped declared secant departure today_levels candidate_levels]
    let changed = ($again.views | each {|v|
        let f = ($first.views | where pose == $v.pose | get -o 0)
        if $f == null { return { pose: $v.pose, fields: ["absent from the first reading"] } }
        { pose: $v.pose, fields: ($fields | where {|k| ($v | get -o $k) != ($f | get -o $k) }) }
    } | where {|x| not ($x.fields | is-empty) })
    { run: $run, tool: $tool, poses: $read, reading_changed: $changed, first: { whole: $first.whole, declared_holds: $first.declared_holds }, again: { whole: $again.whole, declared_holds: $again.declared_holds, revised_holds: ($again | get -o revised_holds) } } | to nuon --indent 2 | save --raw ($out | path join "reread.nuon")
    print $"footprint reread: ($read | length) poses from ($run); ($read | where rows_same | length) block tables the first's byte for byte; ($read | where {|r| $r.still.held } | length) still copies the capture's; the reading's views changed from the first in ($changed | length)"
}

# Each region where a pose's pictures differ cut out of both as PNGs
export def crops [out: path, pose: string, --pad: int = 16] {
    let c = (open ($out | path join $pose "pose.nuon"))
    if $c.pictures == null { error make { msg: $"($pose) was refused at capture: ($c.problems | str join '; ')" } }
    let crops = ($out | path join $pose "crops")
    if ($crops | path exists) { target retire $crops (target root ($GAME | path join .. ..)) }
    mkdir $crops
    let screen = {|label: string| $c.rows | where label == $label | first | get screen }
    for r in ($c.pictures.regions | enumerate) {
        let x0 = ([0 ($r.item.x0 - $pad)] | math max)
        let y0 = ([0 ($r.item.y0 - $pad)] | math max)
        let x1 = ([$c.pictures.width ($r.item.x1 + $pad)] | math min)
        let y1 = ([$c.pictures.height ($r.item.y1 + $pad)] | math min)
        let geometry = $"($x1 - $x0)x($y1 - $y0)+($x0)+($y0)"
        let png = ($crops | path join $"($r.index)_($x0)_($y0).png")
        let join = (if ($x1 - $x0) > ($y1 - $y0) { "-append" } else { "+append" })
        let made = (^magick "(" (do $screen picture) -crop $geometry +repage ")" "(" (do $screen picture_candidate) -crop $geometry +repage ")" $join $png | complete)
        if $made.exit_code != 0 { error make { msg: $"magick for region ($r.index): ($made.stderr)" } }
        print $"region ($r.index): ($r.item.pixels) pixels at most ($r.item.largest) apart in ($geometry), ($png)"
    }
}
