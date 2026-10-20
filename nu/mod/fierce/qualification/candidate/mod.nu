use (path self ../../../../../../jab/nu/mod/bench)
use (path self ../../../../../../jab/nu/mod/build)
use (path self ../../../../../../jab/kit/fierce/nu/mod/gauge)
use (path self ../matrix)
use (path self ../matrix) [JAB MAP STRESS TARGETS]

# The named builds the qualification's bench files declare at jab's HEAD,
# each name one set in every file
def named-builds []: nothing -> list<any> {
    let declared = ($TARGETS | each {|t| open ($JAB | path join "kit" "fierce" "bench" $"qual_($t).nuon") | get -o builds | default [] } | flatten)
    $declared | each {|x| $x.name } | uniq | each {|n|
        let sets = ($declared | where name == $n | each {|x| $x.set } | uniq)
        if ($sets | length) != 1 { error make { msg: $"the bench files build ($n) with the sets ($sets | str join ' and '), where a name is one build" } }
        { name: $n, set: ($sets | first) }
    }
}

# A named build made in its tree at the candidate's commit, as a bench makes
# it, its image's, ELF's, and kernel's SHA-256 and its flags
def named-build [x: record]: nothing -> record {
    let b = (bench build-set $JAB ($JAB | path join kit fierce) $x.set)
    let flags = (open --raw ($b.out | path join "flags") | decode | lines | first)
    {
        set: $x.set, tree: $b.tree, flags: $flags,
        image_sha256: (matrix sha-of ($b.out | path join $"($b.stem).jab")),
        elf_sha256: (matrix sha-of ($b.out | path join $"($b.stem).elf")),
        kernel_sha256: (matrix sha-of $b.kernel),
    }
}

# A repository's HEAD in full, and whether its tree holds changes
def head-of [repo: path]: nothing -> record<commit: string, dirty: bool> {
    let commit = (^git -C $repo rev-parse HEAD | complete | get stdout | str trim)
    let dirty = ((^git -C $repo status --porcelain | complete | get stdout | str trim) != "")
    { commit: $commit, dirty: $dirty }
}

# The candidate at its freeze: the release build, each named build the bench
# files declare made before it, and every digest
export def candidate-of [tag: string]: nothing -> record {
    let repos = [[repo, dir]; [jab $JAB] [stress $STRESS]]
    let heads = ($repos | each {|r|
        let h = (head-of $r.dir)
        if $r.repo == "stress" {
            let named = (if $tag == "" { null } else { ^git -C $r.dir rev-parse $"($tag)^{commit}" | complete })
            let tagged = (if $named == null or $named.exit_code != 0 { null } else { $named.stdout | str trim })
            return { repo: $r.repo, commit: $h.commit, dirty: $h.dirty, tagged: $tagged }
        }
        if $h.dirty { error make { msg: $"($r.dir) holds changes; a candidate is a commit with every file of it committed" } }
        if $tag != "" {
            let named = (^git -C $r.dir rev-parse $"($tag)^{commit}" | complete)
            if $named.exit_code != 0 { error make { msg: $"($r.dir) has no tag ($tag)" } }
            if ($named.stdout | str trim) != $h.commit { error make { msg: $"($tag) names ($named.stdout | str trim) in ($r.dir), whose HEAD is ($h.commit)" } }
        }
        { repo: $r.repo, commit: $h.commit }
    })
    let game = ($JAB | path join kit fierce)
    let builds = (named-builds | reduce --fold {} {|x, acc| $acc | insert $x.name (named-build $x) })
    let built = (^nu ($JAB | path join nu bin do.nu) build $game | complete)
    if $built.exit_code != 0 { error make { msg: $"the release build of ($game): ($built.stdout + $built.stderr | lines | last 6 | str join ' | ')" } }
    let out = (build program-out $game release)
    let image = ($out | path join fierce.jab)
    let elf = ($out | path join fierce.elf)
    let kernel = (build program-kernel $game release)
    for f in [$image $elf $kernel] { if not ($f | path exists) { error make { msg: $"the release build left no ($f)" } } }
    let flags = (open --raw ($out | path join flags) | decode | lines | first)
    if ($flags =~ '--defsym DEBUG=') { error make { msg: $"the release image's flags define DEBUG: ($flags)" } }
    let prefix = ($flags | split row " " | last)
    {
        tag: (if $tag == "" { null } else { $tag }),
        written: (date now | format date "%Y-%m-%dT%H:%M:%S%z"),
        jab: ($heads | where repo == jab | get 0.commit),
        stress: ($heads | where repo == stress | get 0.commit),
        stress_checkout: ($heads | where repo == stress | get 0 | select dirty tagged),
        image_sha256: (matrix sha-of $image),
        elf_sha256: (matrix sha-of $elf),
        kernel_sha256: (matrix sha-of $kernel),
        flags: $flags,
        toolchain: {
            prefix: $prefix,
            version: (try { ^$"($prefix)as" --version | complete | get stdout | lines | get -o 0 } catch { null }),
            tools: { as: (gauge identity resolved-file $"($prefix)as"), ld: (gauge identity resolved-file $"($prefix)ld"), objcopy: (gauge identity resolved-file $"($prefix)objcopy") },
        },
        assets: { map: $MAP, digest: (gauge identity tree-digest (build program-shard $game asset | path join $MAP)) },
        builds: $builds,
    }
}

# The candidate's record at its freeze, written to `out`
export def main [out: path, --tag: string = ""] {
    let c = (candidate-of $tag)
    $c | to nuon --indent 2 | save --raw $out
    print $"qualification: the candidate ($c.tag | default 'untagged') at jab (matrix short $c.jab), jab-stress (matrix short $c.stress), image ($c.image_sha256); ($out)"
}
