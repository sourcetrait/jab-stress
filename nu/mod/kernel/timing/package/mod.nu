use (path self ../../../../../../jab/nu/mod/package)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)

# jab beside the workbench, whose tree the asset tree, the route, and the benches come from
const JAB = (path self ../../../../../../jab | path expand)

# The targets a bench is written for, one bench each
const TARGETS = ["1ka1" "1kb1"]

# The guest inputs' places in the package, as the benches name them
export const PACKAGED = {
    image: "fierce/fierce.jab",
    kernels: { P0: "kernel/p0/jab.elf", P2: "kernel/p2/jab.elf" },
    walks: { walk_await: "walk/await", walk_await_timing: "walk/await_timing", walk_prepare: "walk/prepare", walk_prepare_timing: "walk/prepare_timing" },
    assets: "asset/render_0",
    route: "route/route_render_0.nuon",
}

# A file held to a SHA-256, else refused by name
def held [file: path, sha: string, what: string]: nothing -> string {
    if not ($file | path exists) { error make { msg: $"no ($what) at ($file)" } }
    let found = (open --raw $file | hash sha256)
    if $found != $sha { error make { msg: $"the ($what) ($file) has SHA-256 ($found), where ($sha) is named" } }
    $file
}

# A frozen export's file by its role in the spec's freeze, refused when absent
def frozen [s: record, kind: string, role: string]: nothing -> string {
    let file = ($s.freeze | get $kind | where role == $role | get -o 0.file)
    if $file == null or not ($file | path exists) { error make { msg: $"the spec's freeze names no ($kind | str substring 0..-2) of role ($role) on disk" } }
    $file | path expand
}

# The first fps run's identity of the spec's batteries, the inputs every run played
def played [s: record]: nothing -> record {
    let first = ($s.batteries | each {|b|
        glob ($b.base | path expand | path join "*" "run_*" "identity.nuon") | sort | each {|f| open $f } | where {|id| ($id | get -o build.image) != null }
    } | flatten | get -o 0)
    if $first == null { error make { msg: "the spec's batteries hold no fps run to take the played inputs from" } }
    $first
}

# JointTiming's host package: the frozen exports by role, the asset tree and
# the route every fps run played, and a bench a target, laid by jab's
# package module into one tar
export def main [spec: path, out: path, --stage: string = ""] {
    let s = (open $spec)
    let id = (played $s)
    let fps = (frozen $s images fps)
    let fps_dir = ($fps | path dirname)
    let program = ($fps_dir | path dirname)
    let source = (open ($program | path join "source.nuon"))
    let flags = (open --raw ($fps_dir | path join "flags") | decode | lines | first)
    let prov = (open ($fps_dir | path join "provenance.nuon"))
    let kernels = ($PACKAGED.kernels | columns | each {|k|
        let elf = (frozen $s kernels $k)
        let kprov = (open ($elf | path dirname | path join "provenance.nuon"))
        { rule: $k, elf: $elf, provenance: ($elf | path dirname | path join "provenance.nuon"), elf_sha256: $kprov.elf_sha256, loaded_sha256: $kprov.loaded_sha256, at: ($PACKAGED.kernels | get $k) }
    })
    let walks = ($PACKAGED.walks | columns | each {|r| let image = (frozen $s images $r); { role: $r, image: $image, dir: ($image | path dirname), at: ($PACKAGED.walks | get $r) } })
    let assets = ($id | get assets)
    let tree = $assets.tree
    let digest = (gauge identity tree-digest $tree)
    if $digest != $assets.digest { error make { msg: $"the asset tree ($tree) has digest ($digest), where the runs played ($assets.digest)" } }
    let route = (held $id.route.file $id.route.sha256 "route")
    let benches = ($TARGETS | each {|t| let f = ($JAB | path join "kit" "fierce" "bench" $"jointtiming_($t).nuon"); if not ($f | path exists) { error make { msg: $"jab holds no bench ($f)" } }; { target: $t, file: $f } })
    let head = (^git -C $JAB rev-parse HEAD | complete | get stdout | str trim)
    let dirty = ((^git -C $JAB status --porcelain -- kit/fierce/bench | complete | get stdout | str trim) != "")
    if $dirty { error make { msg: "jab's benches differ from its commit; a package carries committed benches" } }
    let name = $"jointtiming-($head | str substring 0..<10)"
    let stage = (if $stage == "" { $out | path expand | path dirname | path join $"($name).stage" } else { $stage | path expand })
    let made = ($stage | path dirname | path join $"($name).inputs")
    if ($made | path exists) { error make { msg: $"($made) exists; a package's inputs are written once" } }
    mkdir $made
    let image_dir = ($PACKAGED.image | path dirname)
    let spec_out = {
        name: $name,
        artifacts: ([
            { role: "image", from: $fps, at: $PACKAGED.image, meta: { commit: $source.commit, symbols: ($source | get -o symbols | default []), flags: $flags } }
            { role: "elf", from: ($fps_dir | path join "fierce.elf"), at: ($image_dir | path join "fierce.elf") }
            { role: "flags", from: ($fps_dir | path join "flags"), at: ($image_dir | path join "flags") }
            { role: "demand", from: ($fps_dir | path join "demand.nuon"), at: ($image_dir | path join "demand.nuon") }
            { role: "provenance", from: ($fps_dir | path join "provenance.nuon"), at: ($image_dir | path join "provenance.nuon") }
            { role: "source", from: ($program | path join "source.nuon"), at: ($image_dir | path join "source.nuon") }
            { role: "assets", from: $tree, at: $PACKAGED.assets, meta: { map: $assets.map, digest: $digest } }
            { role: "route", from: $route, at: $PACKAGED.route }
        ]
        ++ ($kernels | each {|k| [
            { role: "kernel", from: $k.elf, at: $k.at, meta: { rule: $k.rule, elf_sha256: $k.elf_sha256, loaded_sha256: $k.loaded_sha256 } }
            { role: "kernel provenance", from: $k.provenance, at: ($k.at | path dirname | path join "provenance.nuon") }
        ] } | flatten)
        ++ ($walks | each {|w| [
            { role: "walk image", from: $w.image, at: ($w.at | path join "walk.jab"), meta: { freeze: $w.role } }
            { role: "walk flags", from: ($w.dir | path join "flags"), at: ($w.at | path join "flags") }
            { role: "walk disk", from: ($w.dir | path join "walk.romfs"), at: ($w.at | path join "walk.romfs") }
            { role: "walk provenance", from: ($w.dir | path join "provenance.nuon"), at: ($w.at | path join "provenance.nuon") }
        ] } | flatten)
        ++ ($benches | each {|b| { role: "bench", from: $b.file, at: $"bench/jointtiming_($b.target).nuon" } })),
        identities: {
            freeze: {
                images: ($s.freeze.images | each {|x| { role: $x.role, sha256: (open --raw $x.file | hash sha256) } }),
                kernels: ($kernels | each {|k| { role: $k.rule, elf_sha256: $k.elf_sha256, loaded_sha256: $k.loaded_sha256 } }),
                checks: "every run's identity: its image and kernel the role's file by SHA-256, the ELF for a run and the loaded bytes for a baseline's kernel",
            },
            fps: { commit: $source.commit, image_sha256: $prov.image_sha256, elf_sha256: $prov.elf_sha256 },
            assets: { map: $assets.map, digest: $digest },
            route: { sha256: $id.route.sha256 },
            benches: { source: $"kit/fierce/bench at jab ($head)", targets: $TARGETS },
        },
    }
    let spec_file = ($made | path join "spec.nuon")
    $spec_out | to nuon --indent 2 | save --raw $spec_file
    let result = (package make $spec_file $stage $out)
    print $"timing package: ($result.package), ($result.artifacts) artifacts, ($result.bytes) bytes, SHA-256 ($result.sha256); run it by extracting it and `./do bench kit/fierce/jointtiming_<target> --package <its directory>`"
    $result
}
