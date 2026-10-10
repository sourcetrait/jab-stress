# The eviction fixtures' forced cases as debug candidate trees: jab's
# game/fps `src` copied to <cands>/<name>/game/fps beside a candidate's
# manifest, the checkout's SDK by absolute path and no prepare step, as
# the export writes one, the case's edits applied to its file, each find
# matched exactly once; `pool.just`'s `cand-build` builds a tree, its
# image at <cands>/<name>/game/fps/debug/fps.jab, and `stress.just`'s
# `eviction` runs the fixtures on it.
#
# - construction_skipped (ConstructionSkipped): tile_boundary's call to
#   tile_construct skipped on a frame whose number is a multiple of five,
#   the merge, fold, discard, stamp, occupancy, and their times kept;
#   RebuildBound fails at its publication frames and EvictionCycle at its
#   budget, each on the bay's first fill.

const GAME = (path self | path dirname | path join .. .. .. .. jab game fps)

const CONSTRUCT = ".endif
    call tile_construct
    rdtime t0
"

const SKIPPED = ".endif
    la t0, frame_clock
    ld t0, CLOCK_SNAPSHOT(t0)
    li t1, 5
    remu t0, t0, t1
    beqz t0, 24f                    # every fifth frame's construction skipped
    call tile_construct
24:
    rdtime t0
"

const CASES = [
    { name: "construction_skipped", file: "tile.S", edits: [{ find: $CONSTRUCT, put: $SKIPPED }] }
]

def main [cands: path, ...names: string] {
    let jab = ($GAME | path join .. .. | path expand)
    let sdk = ($jab | path join "sdk")
    let manifest = ([
        "name = 'fps'"
        $"sdk = '($sdk)'"
        $"workspace = '($jab)'"
        $"includes = ['($sdk | path join src)']"
        $"link = '($sdk | path join src program.ld)'"
    ] | str join (char nl)) + (char nl)
    for c in ($CASES | where {|c| ($names | is-empty) or ($c.name in $names) }) {
        let dir = ($cands | path join $c.name "game" "fps")
        let src = ($dir | path join "src")
        if ($dir | path exists) {
            # ours only: a candidate tree of this name, its src replaced
            if not (($dir | path join "program.jab.toml" | path exists) and ($src | path type) == "dir") {
                error make { msg: $"($dir) exists and is not a candidate tree; refusing to replace it" }
            }
            rm -r $src
        } else {
            mkdir $dir
        }
        $manifest | save --raw -f ($dir | path join "program.jab.toml")
        cp -r ($GAME | path join "src") $dir
        let file = ($src | path join $c.file)
        mut text = (open --raw $file)
        for e in $c.edits {
            let n = (($text | split row $e.find | length) - 1)
            if $n != 1 { error make { msg: $"($c.name): a find matched ($n) times, where one is applied: ($e.find | lines | first)" } }
            $text = ($text | str replace $e.find $e.put)
        }
        $text | save --raw -f $file
        print $"($c.name): ($dir)"
    }
}
