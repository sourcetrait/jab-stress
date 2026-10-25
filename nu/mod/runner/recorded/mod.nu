use (path self ../../../../../jab/nu/mod/build)
use (path self ../../../../../jab/nu/mod/target)
use (path self ../hostload)

# jab, checked out beside the workbench
const JAB = (path self ../../../../../jab | path expand)

# The run's directory made once, both checkouts clean, every step's bin found
export def ready [a: record]: nothing -> record<out: string, steps: int> {
    let out = ($a.out | path expand)
    if ($out | path type) != null { error make {msg: $"($out) exists; a run's directory is made once"} }
    for root in [$JAB ($a.stress | path expand)] {
        let held = (checkout-of $root)
        if not $held.clean { error make {msg: $"($root) holds changes; a recorded run names its commits"} }
    }
    if $a.kernel_source != "" {
        let same = (^git -C $JAB diff --quiet $a.kernel_source HEAD -- kernel sdk/src | complete)
        if $same.exit_code != 0 { error make {msg: $"jab's kernel and sdk/src differ from ($a.kernel_source)"} }
    }
    let names = ($a.steps | get name)
    if ($names | uniq | length) != ($names | length) { error make {msg: "two steps share a name"} }
    for s in $a.steps {
        let bin = (bin-of $a $s)
        if ($bin | path type) == null { error make {msg: $"step ($s.name): no bin ($bin)"} }
        build symbols $s.symbols | ignore
        for f in $s.fixtures { fixture-of $a $f | ignore }
        env-of $s | ignore
    }
    mkdir $out
    { out: $out, steps: ($names | length) }
}

# Each step run in turn, its sources, artifacts, and new outputs recorded
export def main [a: record]: nothing -> record<out: string, steps: table<name: string, exit: int, ok: bool, seconds: float>> {
    let out = ($a.out | path expand)
    let target = (target root $JAB)
    let asked = (if $a.kernel_source == "" { null } else { ^git -C $JAB rev-parse $a.kernel_source | str trim })
    let steps = ($a.steps | each {|s|
        let dir = ($out | path join $s.name)
        mkdir $dir
        let names = (build symbols $s.symbols)
        let outs = ($s.outs | each {|o| resolved $o $target $dir })
        let before = ($outs | each {|o| files-of $o })
        let words = ($s.words | each {|w| resolved $w $target $dir })
        let checkouts = { jab: (checkout-of $JAB), stress: (checkout-of ($a.stress | path expand)) }
        let fixtures = ($s.fixtures | each {|f| revision-of $a $f })
        let root = (repo-of $a $s.repo)
        let bin = (bin-of $a $s)
        let given = (env-of $s)
        let ticks = (hostload clock-ticks)
        let load = ($dir | path join "host_load.nuonl")
        let own = (hostload root)
        let started = (date now | format date "%+")
        hostload append-reading $load 0 $ticks
        let sampler = (job spawn { hostload sample $load 1 $ticks })
        let timed = (try { timeit --output { with-env $given { cd $root; ^$bin ...$words | complete } } } catch {|e|
            hostload stop $sampler | ignore
            error make {msg: $"step ($s.name) stopped, its host load read to its stop: ($e.msg)"}
        })
        let final = (hostload stop $sampler)
        let ended = (date now | format date "%+")
        let r = $timed.output
        $r.stdout | save --raw -f ($dir | path join "run.stdout")
        $r.stderr | save --raw -f ($dir | path join "run.stderr")
        let wrote = ($outs | enumerate | each {|e|
            let as = $"out_($e.index)"
            let files = (copied $e.item ($before | get $e.index) ($dir | path join $as))
            { dir: $e.item, as: $as, files: ($files | length), bytes: ($files | reduce --fold 0 {|f, acc| $acc + $f.bytes }) }
        })
        let kernel = (artifact-of ($JAB | path join "kernel") "kernel" $names $dir ($dir | path join "build" "kernel"))
        let programs = ($s.programs | each {|p| artifact-of ($JAB | path join $p) "program" $names $dir ($dir | path join "build" $p) })
        let held = ($kernel.held and ($programs | all {|p| $p.held }))
        let ok = ($r.exit_code == 0 and $held)
        let seconds = ($timed.time / 1sec)
        let last = (^git -C $JAB log -1 --format=%H -- kernel sdk/src | str trim)
        let equal = (if $asked == null { null } else { (^git -C $JAB diff --quiet $asked HEAD -- kernel sdk/src | complete | get exit_code) == 0 })
        {
            name: $s.name,
            repo: $s.repo,
            bin: $s.bin,
            words: $words,
            env: ($s | get -o env | default []),
            symbols: $names,
            started: $started,
            ended: $ended,
            seconds: $seconds,
            exit: $r.exit_code,
            ok: $ok,
            checkouts: $checkouts,
            kernel_source: { asked: $asked, last: $last, equal: $equal },
            fixtures: $fixtures,
            kernel: $kernel,
            programs: $programs,
            outs: $wrote,
            host_load: (hostload summary $load $own $final),
            stdout: "run.stdout",
            stderr: "run.stderr",
        } | to nuon --indent 2 | save --raw -f ($dir | path join "step.nuon")
        { name: $s.name, exit: $r.exit_code, ok: $ok, seconds: $seconds }
    })
    let failed = ($steps | where {|s| not $s.ok })
    if ($failed | is-not-empty) {
        error make {msg: $"steps failed: ($failed | each {|f| $'($f.name) exit ($f.exit)' } | str join ', '); every step recorded in ($out)"}
    }
    { out: $out, steps: $steps }
}

# A step's checkout by the name its step gives, jab or the workbench
def repo-of [a: record, repo: string]: nothing -> string {
    match $repo {
        "jab" => $JAB,
        "stress" => ($a.stress | path expand),
        _ => { error make {msg: $"a step runs in jab or stress, not ($repo)"} },
    }
}

# A step's bin, its path from its checkout's root
def bin-of [a: record, step: record]: nothing -> string {
    repo-of $a $step.repo | path join $step.bin
}

# A word with `{target}` jab's target root and `{step}` the step's directory
def resolved [word: string, target: string, dir: string]: nothing -> string {
    $word | str replace --all "{target}" $target | str replace --all "{step}" $dir
}

# A step's `env` rows as one record, each a text name and value, set once
def env-of [step: record]: nothing -> record {
    $step | get -o env | default [] | reduce --fold {} {|e, acc|
        let name = (try { $e.name } catch { null })
        let value = (try { $e.value } catch { null })
        if (($name | describe) != "string") or ($name == "") or (($value | describe) != "string") {
            error make {msg: $"step ($step.name): an env row is a name and a value, both text"}
        }
        if ($name in ($acc | columns)) { error make {msg: $"step ($step.name): env sets ($name) twice"} }
        $acc | insert $name $value
    }
}

# A checkout's commit and whether its tree holds changes
def checkout-of [root: string]: nothing -> record<commit: string, clean: bool> {
    let commit = (^git -C $root rev-parse HEAD | str trim)
    let changed = (^git -C $root status --porcelain | lines | where {|l| $l != "" })
    { commit: $commit, clean: ($changed | is-empty) }
}

# A fixture named `<repo>:<path>`, held a tracked file of its checkout
def fixture-of [a: record, name: string]: nothing -> record<repo: string, path: string, at: string> {
    let parts = ($name | split row --number 2 ":")
    if ($parts | length) != 2 { error make {msg: $"a fixture is <repo>:<path>, not ($name)"} }
    let root = (repo-of $a $parts.0)
    let tracked = (^git -C $root ls-files --error-unmatch $parts.1 | complete)
    if $tracked.exit_code != 0 { error make {msg: $"fixture ($name): not a tracked file of ($root)"} }
    { repo: $parts.0, path: $parts.1, at: ($root | path join $parts.1) }
}

# A fixture's last commit, its blob, and its bytes' SHA-256 as the step reads it
def revision-of [a: record, name: string]: nothing -> record<repo: string, path: string, commit: string, blob: string, sha256: string> {
    let f = (fixture-of $a $name)
    let root = (repo-of $a $f.repo)
    {
        repo: $f.repo,
        path: $f.path,
        commit: (^git -C $root log -1 --format=%H -- $f.path | str trim),
        blob: (^git -C $root rev-parse $"HEAD:($f.path)" | str trim),
        sha256: (open --raw $f.at | into binary | hash sha256),
    }
}

# The regular files under a directory, each with its size and modification time
def files-of [dir: string]: nothing -> table<rel: string, size: filesize, modified: datetime> {
    if ($dir | path type) != "dir" { return [] }
    let found = (try { ls -a ($dir | path join "**" "*" | into glob) } catch { [] })
    $found | where type == "file" | each {|f| { rel: ($f.name | path relative-to $dir), size: $f.size, modified: $f.modified } }
}

# The files a step wrote or changed under a directory, copied beneath its own
def copied [dir: string, before: table, into: string]: nothing -> table<rel: string, bytes: int> {
    let was = ($before | reduce --fold {} {|f, acc| $acc | upsert $f.rel [$f.size $f.modified] })
    let wrote = (files-of $dir | where {|f| ($was | get -o $f.rel) != [$f.size $f.modified] })
    for f in $wrote {
        let to = ($into | path join $f.rel)
        mkdir ($to | path dirname)
        cp ($dir | path join $f.rel) $to
    }
    $wrote | each {|f| { rel: $f.rel, bytes: ($f.size | into int) } }
}

# A build's outputs copied into the step with their digests, its flags held
def artifact-of [dir: string, kind: string, names: list<string>, step: string, into: string]: nothing -> record {
    let c = (build context $dir $kind $names)
    let stem = (if $kind == "kernel" { "jab" } else { $c.manifest.name })
    let flags_at = ($c.out | path join "flags")
    let flags = (if ($flags_at | path type) == "file" { open --raw $flags_at | decode | lines | get -o 0 } else { null })
    let defined = (if $flags == null { [] } else { $flags | parse --regex '--defsym (?P<n>[A-Za-z0-9_]+)=1' | get n | sort })
    mkdir $into
    let kept = {|name: string|
        let from = ($c.out | path join $name)
        if ($from | path type) != "file" { return null }
        let to = ($into | path join $name)
        cp $from $to
        { from: $from, kept: ($to | path relative-to $step), sha256: (open --raw $to | into binary | hash sha256) }
    }
    do $kept "flags" | ignore
    let elf = (do $kept $"($stem).elf")
    let own = (if $kind == "kernel" {
        if $elf == null { { loaded: null } } else {
            let bin = ($into | path join "jab.bin")
            let made = (^$"($c.prefix)objcopy" -O binary ($into | path join "jab.elf") $bin | complete)
            if $made.exit_code != 0 { error make {msg: $"objcopy of the kernel: ($made.stderr | str trim)"} }
            { loaded: { kept: ($bin | path relative-to $step), sha256: (open --raw $bin | into binary | hash sha256) } }
        }
    } else {
        { program: ($dir | path relative-to $JAB), image: (do $kept $"($stem).jab") }
    })
    {
        tree: $c.profile,
        out: $c.out,
        elf: $elf,
        flags: $flags,
        defined: $defined,
        held: ($defined == $names),
    } | merge $own
}
