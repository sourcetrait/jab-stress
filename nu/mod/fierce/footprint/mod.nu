use (path self ../../../../../jab/nu/mod/target)
use (path self ../../../../../jab/nu/mod/build)
use (path self ../../../../../jab/nu/mod/launch)
use (path self ../../../../../jab/kit/fierce/nu/mod/pose)
use (path self ../../../../../jab/kit/fierce/nu/mod/console)
use (path self ../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../../../../jab/kit/fierce/nu/mod/picture)
use (path self ../../../../../jab/kit/fierce/nu/mod/map)
use (path self ../freeze) [symbols-of provenance-of]
use (path self ../workerparity) [disk-of answered-frames]

# The game's directory in jab, checked out beside the workbench
const GAME = path self ../../../../../jab/kit/fierce

# The images an export is built as, each a label and its set
const BUILDS = [
    [label, set];
    [picture, "debug"]
    [picture_candidate, "debug,footprint"]
    [owner, "debug,owner"]
    [levels, "debug,levels"]
    [levels_candidate, "debug,footprint,levels"]
]

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

# The console's P frame with the pose's roll
def placement [p: record]: nothing -> binary {
    let floats = ([$p.x $p.y $p.z $p.yaw $p.pitch $p.roll] | each {|f| $f | into float })
    [("P" | into binary), 0x[00 00 00], ($floats | each {|f| map float-bytes $f } | bytes collect), (0..<36 | each {|i| 0x[00] } | bytes collect)] | bytes collect
}

# A launch's sends under the picture contract, the serial backend's
def sends-of [p: record]: nothing -> list<any> {
    [
        { at: $STAMP_AT, bytes: (console raise 0 --stamp) }
        { at: $STAMP_AT, bytes: (console workers 0 0) }
        { at: 1900ms, bytes: (pose command-frame "L") }
        { at: 2000ms, bytes: (placement $p) }
        { at: 8000ms, bytes: (placement $p) }
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
            label: $b.label, set: $b.set, symbols: $names, image: $image, image_sha256: $provenance.image_sha256,
            elf_sha256: $provenance.elf_sha256, kernel: $kernel, kernel_sha256: (open --raw $kernel | into binary | hash sha256),
            kernel_loaded_sha256: (open --raw $bin | into binary | hash sha256), flags: $flags,
        }
        $images = ($images | append $entry)
        print $"($b.label): ($image), SHA-256 ($entry.image_sha256), the kernel's loaded bytes ($entry.kernel_loaded_sha256)"
    }
    let loaded = ($images | get kernel_loaded_sha256 | uniq)
    if ($loaded | length) != 1 { error make { msg: $"the images' kernels load different bytes: ($images | select label kernel_loaded_sha256 | to nuon)" } }
    { export: $export, commit: $source.commit, images: $images } | to nuon --indent 2 | save --raw $record
    print $"footprint images: ($images | length) built from ($source.commit), one kernel's code under all"
}

# A map's still disk for a capture, made once in `out` and reused
def disk-for [map: string, out: path]: nothing -> record {
    let dir = ($out | path join $"disk_($map)")
    let record = ($dir | path join "disk.nuon")
    if ($record | path exists) {
        let disk = (open $record)
        let now = (open --raw $disk.disk | hash sha256)
        if $now != $disk.sha256 { error make { msg: $"($disk.disk) has SHA-256 ($now) where its record says ($disk.sha256)" } }
        return $disk
    }
    mkdir $dir
    let disk = (disk-of $map $dir)
    let made = ($disk | insert map (($disk.tree | path join "map" $"($disk.name).jabfps.map")))
    $made | to nuon --indent 2 | save --raw $record
    $made
}

# A launch's row: its label, status, screen, faults, and binding
def row-of [run: record, image: record, p: record]: nothing -> record {
    let lines = ($run.serial | lines)
    {
        label: $image.label, status: $run.status, screen: $run.screen,
        screen_sha256: (if $run.screen != "" { open --raw $run.screen | hash sha256 } else { null }),
        faults: ($lines | where {|l| ($l starts-with "jab: ") and (($l =~ "fault") or ($l =~ "shutdown")) }),
        binding: (bind $run $p ("LEVELS" in $image.symbols)),
    }
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
    let image = {|label: string| $made.images | where label == $label | first }
    for p in $chosen {
        let dir = ($out | path join $p.name)
        if ($dir | path join "pose.nuon" | path exists) { error make { msg: $"($dir) holds a capture; a pose is captured once into an out" } }
        let disk = (disk-for $p.map $out)
        let rows = ($made.images | each {|i|
            let run = (launch --kernel $i.kernel --image $i.image --out ($dir | path join $i.label) --set $i.set --sound --api --disk $disk.disk --serial "fps" --send (sends-of $p) --screen $SCREEN_AT --seconds $SECONDS)
            row-of $run $i $p
        })
        let problems = ($rows | each {|r|
            let own = ($r.binding.problems | each {|x| $"($r.label): ($x)" })
            let status = (if $r.status != $BOUND_STATUS { [$"($r.label): status ($r.status), where the bound's ($BOUND_STATUS) was expected"] } else { [] })
            let faults = ($r.faults | each {|f| $"($r.label): ($f)" })
            $own ++ $status ++ $faults
        } | flatten)
        let screen = {|label: string| $rows | where label == $label | first | get screen }
        let reference = (if not ($problems | is-empty) { null } else {
            let s = ($rows | where label == levels | first | get binding.state)
            let r = (^$tool.path reference $disk.map $disk.tree $s.x $s.y $s.z $s.yaw $s.pitch $s.roll (do $screen owner) (do $screen levels) (do $screen levels_candidate) --rows ($dir | path join "rows.nuon") | complete)
            if $r.exit_code != 0 { error make { msg: $"the reference at ($p.name): ($r.stderr)" } }
            $r.stdout | from nuon
        })
        let pictures = (if not ($problems | is-empty) { null } else {
            let d = (^$tool.path differ (do $screen picture) (do $screen picture_candidate) | complete)
            if $d.exit_code != 0 { error make { msg: $"the pictures at ($p.name): ($d.stderr)" } }
            $d.stdout | from nuon
        })
        { pose: $p, disk: $disk, export: $export, commit: $made.commit, tool: $tool, rows: $rows, reference: $reference, pictures: $pictures, problems: $problems } | to nuon --indent 2 | save --raw ($dir | path join "pose.nuon")
        if ($problems | is-empty) {
            let today = ($reference.captures | get 0)
            let cand = ($reference.captures | get 1)
            print $"($p.name): ($today.judged) blocks judged, ($today.sensitive) in a band; today ($today.sharper) sharper ($today.coarser) coarser, the candidate ($cand.sharper) sharper ($cand.coarser) coarser; by the secant today ($today.secant_sharper) and ($today.secant_coarser), the candidate ($cand.secant_sharper) and ($cand.secant_coarser); the pictures differ in ($pictures.pixels) pixels, ($pictures.regions | length) regions"
        } else {
            print $"($p.name): refused, ($problems | str join '; ')"
        }
    }
}

# A level's verdict against a reference level and its band
def judged [level: int, reference: int, band: any]: nothing -> string {
    let least = (if $band == null { $reference } else { $band - 1 })
    let most = (if $band == null { $reference } else { $band })
    if $level < $least { "sharper" } else if $level > $most { "coarser" } else { "agree" }
}

# A pose's judged blocks read one by one, by both references
def blocks-of [rows: path]: nothing -> record {
    let read = (open $rows | where {|r| ($r.levels | get 0) != null and ($r.levels | get 1) != null } | each {|r|
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

# Every captured pose judged, reading.nuon written
export def read [out: path] {
    let captured = (glob ($out | path join "*" "pose.nuon") | sort | each {|f| open $f })
    if ($captured | is-empty) { error make { msg: $"no pose captured in ($out)" } }
    let refused = ($captured | where {|c| not ($c.problems | is-empty) } | each {|c| { pose: $c.pose.name, problems: $c.problems } })
    let views = ($captured | where {|c| $c.problems | is-empty } | each {|c|
        let today = ($c.reference.captures | get 0)
        let cand = ($c.reference.captures | get 1)
        {
            pose: $c.pose.name, map: $c.pose.map, judged: $today.judged, sensitive: $today.sensitive, clamped: $today.clamped,
            declared: (verdict-of $today $cand ""), secant: (verdict-of $today $cand "secant_"),
            blocks: (blocks-of ($out | path join $c.pose.name "rows.nuon")),
            today_levels: $today.levels, candidate_levels: $cand.levels,
            pictures: { pixels: $c.pictures.pixels, regions: ($c.pictures.regions | length), largest: ($c.pictures.regions | get -o largest | default [] | append 0 | math max) },
        }
    })
    let declared = (($views | length) > 0 and ($refused | is-empty) and ($views | all {|v| $v.declared.holds }))
    let secant = (($views | length) > 0 and ($refused | is-empty) and ($views | all {|v| $v.secant.holds }))
    let own = ($views | get blocks.own_sharper | math sum)
    for v in $views {
        let b = $v.blocks
        print $"($v.pose): ($v.judged) judged, ($v.sensitive) in a band, ($v.clamped) clamped; declared today ($v.declared.today) off, the candidate ($v.declared.candidate) with ($v.declared.candidate_sharper) sharper, (if $v.declared.holds { 'holds' } else { 'fails' }); secant today ($v.secant.today), the candidate ($v.secant.candidate) with ($v.secant.candidate_sharper) sharper, (if $v.secant.holds { 'holds' } else { 'fails' }); the pictures ($v.pictures.pixels) pixels in ($v.pictures.regions) regions, at most ($v.pictures.largest) apart"
        print $"  blocks: levels differing in ($b.levels_differ); sharper for both ($b.shared_sharper), the candidate's own ($b.own_sharper), today's own ($b.today_own_sharper); the along step's, today ($b.along_today.blocks) and the candidate ($b.along_candidate.blocks), the along term deciding in ($b.along_candidate.along_decides) of the candidate's, its step over the start's derivative ($b.along_candidate.ratio | default [] | each {|x| $x | math round --precision 3 } | str join ' to ')"
    }
    for r in $refused { print $"($r.pose): refused, ($r.problems | str join '; ')" }
    { views: $views, refused: $refused, declared_holds: $declared, secant_holds: $secant, own_sharper: $own } | to nuon --indent 2 | save --raw -f ($out | path join "reading.nuon")
    print $"footprint read: ($views | length) views, ($refused | length) refused; the declared criteria (if $declared { 'hold' } else { 'fail' }), the secant's (if $secant { 'hold' } else { 'fail' }); the candidate's own sharper blocks by the declared reference ($own)"
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
