use ./live
use ./rules

const CONTRACT = path self ../../../../../jab-stress-data/assets/jab/importmap/contract.nuon

# The checkout's commit and whether its tree holds changes.
def head-of [root: path]: nothing -> record<commit: string, dirty: bool> {
    let commit = (^git -C $root rev-parse HEAD | complete | get stdout | str trim)
    let changed = (^git -C $root status --porcelain | complete | get stdout | str trim)
    {commit: $commit, dirty: ($changed != '')}
}

# Every declaration of the nu files and the runners' bodies, with its place.
def declared [sources: table]: nothing -> table {
    mut found = []
    for s in ($sources | where {|s| $s.kind in ['nu' 'descriptor'] }) {
        let here = (live declarations-of $s.src | each {|d| $d | insert repo $s.repo | insert file $s.file })
        $found = ($found | append $here)
    }
    $found
}

# The signatures of the files the contract's defs live in, old or new.
def signed [contract: record, landed: list<string>, sources: table]: nothing -> record {
    let olds = ($contract.defs | where file != null | each {|d|
        [$d.repo (rules mapped $contract $landed $d.repo $d.file)] | str join '|'
    })
    let news = ($contract.modules | each {|m| [$m.repo $m.file] | str join '|' })
    let wanted = ($olds | append $news | uniq)
    mut sigs = {}
    for s in ($sources | where kind == 'nu') {
        let key = ([$s.repo $s.file] | str join '|')
        if $key in $wanted { $sigs = ($sigs | upsert $key (live signatures-of $s.src)) }
    }
    $sigs
}

# The live trees of jab and jab-stress held to the migration contract.
export def check [jab: path, stress: path, --landed: string = '', --contract: string = '', --out: string = '']: [
    nothing -> record<ok: bool, landed: list<string>, refusals: int, checked: record, report: string>
] {
    let file = (if $contract == '' { $CONTRACT } else { $contract | path expand })
    let c = (open $file)
    let done = ($landed | split row ',' | each {|g| $g | str trim } | where {|g| $g != '' })
    let unknown = ($done | where {|g| $g not-in ($c.groups | get group) })
    if ($unknown | is-not-empty) { error make {msg: $"groups the contract does not name: ($unknown | str join ', ')"} }
    let roots = {jab: ($jab | path expand), jab-stress: ($stress | path expand)}
    let sources = ((live sources-of jab $roots.jab) | append (live sources-of jab-stress ($roots | get jab-stress)))
    let decls = (declared $sources)
    let sigs = (signed $c $done $sources)
    let imported = (rules import-rules $c $roots $sources)
    let consumed = (rules consumer-rules $c $roots $sources)
    let refusals = ((rules places $c $done $decls $sigs)
        | append (rules constants $c $done $decls)
        | append (rules files $c $done $decls)
        | append (rules ownership $c $done $decls)
        | append $imported.refusals
        | append $consumed.refusals
        | append (rules bin-rules $c $sources $decls)
        | append (rules case-rules $c $done $sources $decls $sigs)
        | append (rules transformation-rules $c $done $decls))
    let checked = {
        sources: ($sources | length), declarations: ($decls | length), contract_defs: ($c.defs | length),
        imports: $imported.edges, consumer_calls: $consumed.calls
    }
    let report = (if $out == '' { '' } else {
        let dir = ($out | path expand)
        mkdir $dir
        {
            contract: {file: $file, sha256: (open --raw $file | into binary | hash sha256), commits: $c.commits}
            trees: {jab: (head-of $roots.jab), jab-stress: (head-of ($roots | get jab-stress))}
            landed: $done, checked: $checked, refusals: $refusals
        } | to nuon --indent 1 | save ($dir | path join 'report.nuon')
        $dir | path join 'report.nuon'
    })
    {ok: ($refusals | is-empty), landed: $done, refusals: ($refusals | length), checked: $checked, report: $report}
}
