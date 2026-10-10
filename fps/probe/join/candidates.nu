# JoinBeforeBoundary's forced cases as debug candidate trees: jab's
# game/fps `src` copied to <cands>/<name>/game/fps beside a candidate's
# manifest, the checkout's SDK by absolute path and no prepare step, as
# the export writes one, the case's edits applied to `src/workers.S`,
# each find matched exactly once; `pool.just`'s `cand-build` builds a
# tree and `eviction.just`'s `hold-on` reads its exit.
#
# - join_released: round_run's join loop, its release among it, and the
#   round's debug checks after it removed; held, the next boundary's
#   entry finds the held job incomplete, exit 15.
# - release_dropped: the join loop's release removed, the join kept;
#   held, the hold expires, the job completes, and the next boundary's
#   entry reads the expiry, exit 16.

const GAME = (path self | path dirname | path join .. .. .. .. jab game fps)

const JOIN_LOOP = "    li s3, 0
5:
    bgeu s3, s1, 6f
    slli s6, s3, 7
    la t0, mailboxes
    add s6, s6, t0
.ifdef DEBUG
    addi t0, s3, 1
    sw t0, ROUND_RELEASE(s0)        # the join reached this index: its held worker released
.endif
    jab.job.join s6
    addi s3, s3, 1
    j 5b
6:
"

const RELEASE = ".ifdef DEBUG
    addi t0, s3, 1
    sw t0, ROUND_RELEASE(s0)        # the join reached this index: its held worker released
.endif
    jab.job.join s6
"

const CHECKS = "85:
.ifdef DEBUG
    li s3, 0
86:
    bgeu s3, s1, 87f
    slli s6, s3, 7
    la t0, mailboxes
    add s6, s6, t0
    lw t0, JAB_JOB_DONE(s6)
    lw t1, JAB_JOB_GEN(s6)
    addi s3, s3, 1
    beq t0, t1, 86b                 # its job joined, the round's
    jab.sys.uart.print msg_unjoined
    jab.sys.exit 13
87:
    ld t1, 16(sp)
    lwu t2, ROUND_BANDS(s0)
    beq t1, t2, 90f
    jab.sys.uart.print msg_lost_bands
    jab.sys.exit 13
.endif
90:
"

const CASES = [
    { name: "join_released", edits: [{ find: $JOIN_LOOP, put: "6:\n" }, { find: $CHECKS, put: "85:\n90:\n" }] }
    { name: "release_dropped", edits: [{ find: $RELEASE, put: "    jab.job.join s6\n" }] }
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
        let file = ($src | path join "workers.S")
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
