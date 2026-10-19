use (path self ./edits)

# The game's directory in jab, checked out beside the workbench
const GAME = path self ../../../../../../../jab/kit/fierce

# The cases: each a layout and the classes it tiles
const CASES = [
    { name: "rows_walls", layout: "LAYOUT_ROWS", classes: "TILE_CLASS_WALLS" }
    { name: "blocks_walls", layout: "LAYOUT_BLOCKS", classes: "TILE_CLASS_WALLS" }
    { name: "morton_walls", layout: "LAYOUT_MORTON", classes: "TILE_CLASS_WALLS" }
    { name: "rows_planes", layout: "LAYOUT_ROWS", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "blocks_planes", layout: "LAYOUT_BLOCKS", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "morton_planes", layout: "LAYOUT_MORTON", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "rows_count", layout: "LAYOUT_ROWS", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "blocks_count", layout: "LAYOUT_BLOCKS", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
    { name: "morton_count", layout: "LAYOUT_MORTON", classes: "(TILE_CLASS_WALLS | TILE_CLASS_PLANES)" }
]

# Each case's candidate tree written from the game's src at a commit
export def main [cands: path, commit: string, ...names: string] {
    let jab = ($GAME | path join .. .. | path expand)
    let head = (^git -C $jab rev-parse HEAD | str trim)
    if not ($head | str starts-with $commit) {
        error make { msg: $"the checkout is at ($head), not ($commit)" }
    }
    let changed = (^git -C $jab status --porcelain -- kit/fierce/src | str trim)
    if $changed != "" { error make { msg: $"the checkout's src has changes: ($changed)" } }
    let unknown = ($names | where {|n| $n not-in ($CASES | get name) })
    if ($unknown | is-not-empty) { error make { msg: $"no such case: ($unknown | str join ', ')" } }
    let sdk = ($jab | path join "sdk")
    let manifest = ([
        "name = 'fps'"
        $"sdk = '($sdk)'"
        $"workspace = '($jab)'"
        $"includes = ['($sdk | path join src)']"
        $"link = '($sdk | path join src program.ld)'"
    ] | str join (char nl)) + (char nl)
    for c in ($CASES | where {|c| ($names | is-empty) or ($c.name in $names) }) {
        let dir = ($cands | path join $"layout_($c.name)_($commit)")
        let src = ($dir | path join "src")
        if ($dir | path exists) {
            if not (($dir | path join "program.jab.toml" | path exists) and ($src | path type) == "dir") {
                error make { msg: $"($dir) exists and is not a candidate tree; refusing to replace it" }
            }
            rm -r $src
        } else {
            mkdir $dir
        }
        $manifest | save --raw -f ($dir | path join "program.jab.toml")
        cp -r ($GAME | path join "src") $dir
        for e in (edits $c.layout $c.classes) {
            let file = ($src | path join $e.file)
            let text = (open --raw $file | decode utf-8)
            let n = (($text | split row $e.find | length) - 1)
            if $n != 1 {
                error make { msg: $"($c.name): a find in ($e.file) matched ($n) times, where one is applied: ($e.find | lines | first)" }
            }
            $text | str replace $e.find $e.put | save --raw -f $file
        }
        print $"($c.name): ($dir)"
    }
}
