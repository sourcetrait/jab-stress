use (path self ../../tilesources)
use (path self ../builds) [IMAGES iz-min-of]
use (path self ../captures) [GAME KINDS bind disk-for footprint-tool]
use (path self ../verdicts) [read READING_FIELDS]

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

# A reread's own record in its `out`, beside the runner's `reread.nuon`
const AGAIN = "again.nuon"

# A reading's whole verdicts, each null in a reading whose reader held none
const VERDICTS = [whole declared_holds secant_holds departures_hold revised_holds own_sharper]

# The files of a still copy the crate's reference reads: its map and its images
const REFERENCE_READS = ['\.jabfps\.map$' '\.png$']

# A still copy's files held to the capture's inventory rows, each difference
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

# A still copy remade in `into` as a checkout compiled it before jab c804ccb
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
    tilesources rooted $tree $content
    let made = (^genromfs -d $tree -f ($into | path join ($disk.disk | path basename)) -V "fps" | complete)
    if $made.exit_code != 0 { error make { msg: $"genromfs over ($tree): ($made.stderr)" } }
    { content: $content, problems: [] }
}

# A still copy made again and held file by file to the capture's inventory
def still-held [disk: record, out: path, inventory: list<any>, c: record]: nothing -> record<problems: list<string>, differ: list<string>, remade_problems: list<string>, remade_differ: list<string>, disk: record> {
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
    let result = { problems: $problems, differ: ($differ | each {|d| $d.path }), remade_problems: ($remade | get -o problems | default []), remade_differ: ($after | default [] | each {|d| $d.path }), disk: { first: $c.disk.sha256, again: $disk.sha256, remade: $remade_sha, content: ($remade | get -o content), held: $held } }
    $result | to nuon --indent 2 | save --raw $kept
    $result
}

# One captured pose read again from a restoration, held to its pose set's row
def reread-pose [tree: path, out: path, inventory: list<any>, images: list<any>, c: record, tool: record, listed: any]: nothing -> record {
    let name = $c.pose.name
    let unlisted = (if $listed == null { [$"the pose set holds no pose ($name)"] } else {
        let fields = (($c.pose | columns) ++ ($listed | columns) | uniq | where {|k| $k not-in $READING_FIELDS and ($c.pose | get -o $k) != ($listed | get -o $k) })
        if ($fields | is-empty) { [] } else { [$"the pose set's ($name) differs from the captured pose in ($fields | str join ', ')"] }
    })
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
    let no_span = ($kind.levels | enumerate | where {|e| ($c.reference | get -o captures | default [] | get -o $e.index | get -o snapshot) == null } | each {|e| $e.item })
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
    let problems = ($missing ++ $disk_problems ++ $unlisted ++ ($reference | get -o problems | default []))
    {
        pose: $c.pose, disk: $disk, export: $c.export, commit: $c.commit, tool: $tool, launch: ($c | get -o launch), rows: ($launches | get row),
        reference: ($reference | get -o value), pictures: $pictures, problems: $problems,
        reread: {
            from: ($tree | path join $name "pose.nuon"), first_tool: $c.tool, differences: ($launches | get differences | flatten), no_span_table: $no_span, still: $held.disk,
            rows_sha256: $rows_sha, first_rows_sha256: $recorded_rows, rows_same: ($rows_sha != null and $rows_sha == $recorded_rows),
            pictures_same: (if $pictures == null { null } else { not $picture_differs }),
        },
    } | to nuon --indent 2 | save --raw ($dir | path join "pose.nuon")
    { pose: $name, problems: $problems, differences: ($launches | get differences | flatten), no_span_table: $no_span, still: $held.disk, rows_same: ($rows_sha != null and $rows_sha == $recorded_rows), pictures_same: (if $pictures == null { null } else { not $picture_differs }) }
}

# A restored footprint run read again against a pose set, the first beside it
export def reread [tree: path, out: path, poses: path]: nothing -> nothing {
    let tree = ($tree | path expand)
    let out = ($out | path expand)
    let run = (restored-run $tree)
    let inventory = (open ($run | path join "inventory.nuon"))
    let images = (open ($tree | path join "images" $IMAGES) | get images)
    let captured = (glob ($tree | path join "*" "pose.nuon") | sort | each {|f| open $f })
    if ($captured | is-empty) { error make { msg: $"no pose captured in ($tree)" } }
    let set = (open $poses)
    mkdir $out
    let tool = (footprint-tool)
    let taken = ($out | path join "poses.nuon")
    cp $poses $taken
    let read = ($captured | each {|c| reread-pose $tree $out $inventory $images $c $tool ($set | where name == $c.pose.name | get -o 0) })
    for r in $read {
        let rows = (if $r.rows_same { "its block table the first's byte for byte" } else { "its block table another than the first's" })
        let still = (if $r.still.held { "its still copy the capture's" } else { "its still copy not the capture's" })
        print $"($r.pose): (if ($r.problems | is-empty) { 'read again' } else { $r.problems | str join '; ' }); ($rows); ($still); ($r.differences | length) differences from the first reading"
    }
    read $out $taken
    let first = (open ($tree | path join "reading.nuon"))
    let again = (open ($out | path join "reading.nuon"))
    let fields = [judged sensitive clamped resolved iz_min floor_depth declared secant departure today_levels candidate_levels]
    let held = ($fields | where {|k| $first.views | all {|v| $k in ($v | columns) } })
    let changed = ($again.views | each {|v|
        let f = ($first.views | where pose == $v.pose | get -o 0)
        if $f == null { return { pose: $v.pose, fields: ["absent from the first reading"] } }
        { pose: $v.pose, fields: ($held | where {|k| ($v | get -o $k) != ($f | get -o $k) }) }
    } | where {|x| not ($x.fields | is-empty) })
    let verdicts = {|r: record| $VERDICTS | reduce --fold {} {|k, acc| $acc | insert $k ($r | get -o $k) } }
    {
        run: $run, tool: $tool, poses: $read, reading_changed: $changed, compared: $held, first_lacks: ($fields | where {|k| $k not-in $held }),
        first: (do $verdicts $first), again: (do $verdicts $again),
    } | to nuon --indent 2 | save --raw ($out | path join $AGAIN)
    print $"footprint reread: ($read | length) poses from ($run); ($read | where rows_same | length) block tables the first's byte for byte; ($read | where {|r| $r.still.held } | length) still copies the capture's; the reading's views changed from the first in ($changed | length)"
}
