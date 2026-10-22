use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../../tilesources)

# The game in jab, whose map bin compiles a map's tree
const GAME = (path self ../../../../../../jab/kit/fierce | path expand)

# The disks' file in `out`
const DISKS = "disks.nuon"

# A step's one asset tree as its runs' identities record it, or each named
def assets-of [bench: path, step: string]: nothing -> record<key: any, problems: list<string>> {
    let ids = (glob ($bench | path join $step "run_*" "identity.nuon") | sort | each {|f| open $f })
    if ($ids | is-empty) { return { key: null, problems: [$"($step) holds no run's identity"] } }
    let keys = ($ids | each {|i| { map: $i.assets.map, digest: $i.assets.digest, content: ($i.program.dir | path join "content") } } | uniq)
    if ($keys | length) != 1 { return { key: null, problems: [$"($step)'s runs record ($keys | length) asset trees, where a step plays one"] } }
    { key: ($keys | first), problems: [] }
}

# An asset tree compiled again from today's content into `dir`, and its disk
def made-again [key: record, dir: path]: nothing -> record {
    let ran = (^nu ($GAME | path join "nu" "bin" "nuance" "map.nu") compile ($GAME | path join "content" "map" $"($key.map).nuon") $dir --content ($GAME | path join "content") | complete)
    if $ran.exit_code != 0 { error make { msg: $"compiling ($key.map): ($ran.stderr | str trim)" } }
    let tree = ($dir | path join $key.map)
    let again = (gauge identity tree-digest $tree)
    let rooted = (if $again == $key.digest { null } else {
        tilesources rooted $tree $key.content
        gauge identity tree-digest $tree
    })
    let disk = ($dir | path join $"($key.map).romfs")
    let made = (^genromfs -d $tree -f $disk -V "fps" | complete)
    if $made.exit_code != 0 { error make { msg: $"genromfs over ($tree): ($made.stderr)" } }
    { map: $key.map, digest: $key.digest, content: $key.content, again: $again, rooted: $rooted, held: ($again == $key.digest or $rooted == $key.digest), disk: (open --raw $disk | hash sha256) }
}

# A bench's disk copies made again from today's content, held to its records
export def main [bench: path, inventory: path, out: path]: nothing -> nothing {
    let bench = ($bench | path expand)
    let out = ($out | path expand)
    if ($out | path exists) { error make { msg: $"($out) exists; a bench's disks are made again once" } }
    let rows = (open $inventory | where {|r| ($r.path | path basename) =~ '\.romfs$' })
    if ($rows | is-empty) { error make { msg: $"($inventory) lists no disk copy" } }
    mkdir $out
    let steps = ($rows | each {|r| let s = ($r.path | path split | first); { row: $r, step: $s, assets: (assets-of $bench $s) } })
    let keys = ($steps | where {|s| $s.assets.key != null } | get assets.key | uniq)
    let made = ($keys | enumerate | each {|e| made-again $e.item ($out | path join $"assets_($e.index)") })
    let copies = ($steps | each {|s|
        let m = (if $s.assets.key == null { null } else { $made | where {|x| $x.map == $s.assets.key.map and $x.digest == $s.assets.key.digest and $x.content == $s.assets.key.content } | first })
        let named = (if $m != null and ($s.row.path | path basename) != $"($m.map).romfs" { [$"($s.row.path) is no copy of ($m.map)"] } else { [] })
        let problems = ($s.assets.problems ++ $named ++ (if $m != null and $m.held and $m.disk != $s.row.sha256 { [$"($s.row.path) is made again at SHA-256 ($m.disk), the inventory's ($s.row.sha256)"] } else { [] }) ++ (if $m != null and not $m.held { [$"($m.map)'s tree is made again at digest ($m.rooted | default $m.again), the identities' ($m.digest)"] } else { [] }))
        { path: $s.row.path, sha256: $s.row.sha256, made: ($m | get -o disk), held: ($problems | is-empty), problems: $problems }
    })
    let held = ($copies | all {|c| $c.held })
    { bench: $bench, inventory: ($inventory | path expand), assets: $made, copies: $copies, held: $held } | to nuon --indent 2 | save --raw ($out | path join $DISKS)
    for m in $made { print $"qualification disks: ($m.map) compiled again at digest ($m.again)(if $m.rooted == null { '' } else { $', rooted under ($m.content) at ($m.rooted)' }), the identities' ($m.digest): (if $m.held { 'held' } else { 'not held' })" }
    for c in ($copies | where {|c| not $c.held }) { print $"qualification disks: ($c.problems | str join '; ')" }
    print $"qualification disks: ($copies | where held | length) of ($copies | length) disk copies the inventory's; ($out | path join $DISKS)"
    if not $held { error make { msg: $"($bench): ($copies | where {|c| not $c.held } | length) disk copies not held" } }
}
