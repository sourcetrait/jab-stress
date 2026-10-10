# The dump reader's own mutants: a mirror of tiles.nu with one refusal
# rule removed each, read over the builder capture and its alterations
# by alter_probe.nu's cases; each mutant must lose its own fixture. A
# mutant removes its rule's effect, never only its reason's name: the
# orphan, truncated, and unfinished problems are omitted outright, the
# parsing going on as before.

def main [tiles: path, probe: path, api: path, work: path] {
    let source = (open --raw $tiles)
    let probe_text = (open --raw $probe)
    # the probe's one import of tiles.nu, swapped for each mutant's mirror
    let import = '(?m)^use .*tiles\.nu \[dumps\]$'
    let imports = ($probe_text | lines | where {|l| $l =~ '^use .*tiles\.nu \[dumps\]$' } | length)
    if $imports != 1 { error make { msg: $"the probe imports tiles.nu ($imports) times, where one import is swapped for each mirror" } }
    let mutants = [
        { name: "header_schema", fixture: "header_schema", find: "$bad = ((do $word $SCHEMA_AT) != $SCHEMA)", put: "$bad = false" }
        { name: "missing", fixture: "dropped", find: "else if $first > $next { \"missing\" }", put: "else if false { \"missing\" }" }
        { name: "repeated", fixture: "repeated", find: "else if $first == ($next - $DUMP_TEXELS) { \"repeated\" }", put: "else if false { \"repeated\" }" }
        { name: "order", fixture: "swapped", find: "else if $first < $next { \"order\" }", put: "else if false { \"order\" }" }
        { name: "slot", fixture: "slot", find: "(if $slot != $tile.slot {", put: "(if false {" }
        { name: "schema", fixture: "schema", find: "(if $schema != $SCHEMA {", put: "(if false {" }
        { name: "first", fixture: "first", find: "if ($first mod $DUMP_TEXELS) != 0 { \"first texel\" }", put: "if false { \"first texel\" }" }
        { name: "padding", fixture: "padding", find: "(if $count == $DUMP_RECORDS and ($past | is-not-empty) {", put: "(if false {" }
        { name: "count", fixture: "tail_dropped", find: "(if $count != $DUMP_RECORDS {", put: "(if false {" }
        { name: "orphan", fixture: "orphan_before", find: "                $problems = ($problems | append { reason: \"orphan\", record: $at, dump: $dump, found: \"a texel record outside any tile\" })\n", put: "                null\n" }
        { name: "truncated", fixture: "truncated", find: "            $problems = ($problems | append { reason: \"truncated\", record: $at, dump: $dump, found: $\"($r | bytes length) bytes of ($RECORD)\" })\n            break\n", put: "            break\n" }
        { name: "unfinished", fixture: "unfinished", find: "        $problems = ($problems | append { reason: \"unfinished\", record: $ending, dump: ($dumps | length), found: \"a dump the capture ends inside, its D unanswered\" })\n", put: "        null\n" }
        { name: "kind_low_byte", fixture: "kind_high", find: "        let kind = (do $word 0)\n", put: "        let kind = ($r | bytes at 0..<1 | into int)\n" }
        { name: "foreign_skipped", fixture: "foreign_inserted", find: "        } else if $open {\n            let what = (if $kind == $CONSOLE_KIND { $\"kind ($kind), command ($command)\" } else { $\"kind ($kind)\" })\n            $problems = ($problems | append { reason: \"foreign\", record: $at, dump: $dump, found: $\"a record of ($what) inside the dump\" })\n            if $tile != null { $bad = true }\n        }\n", put: "        }\n" }
        { name: "command_low_byte", fixture: "answer_command", find: "        let command = (do $word 4)\n", put: "        let command = ($r | bytes at 4..<5 | into int)\n" }
    ]
    mkdir $work
    let rows = ($mutants | each {|m|
        let n = (($source | split row $m.find | length) - 1)
        if $n != 1 { return { mutant: $m.name, applied: false, matches: $n, lost: [], own: false } }
        let dir = ($work | path join $m.name)
        mkdir $dir
        let mirror = ($dir | path join "tiles.nu")
        $source | str replace $m.find $m.put | save --raw -f $mirror
        let p = ($dir | path join "probe.nu")
        $probe_text | str replace --regex $import $"use ($mirror) [dumps]" | save --raw -f $p
        let r = (^/usr/bin/nu $p $api | complete)
        if $r.exit_code != 0 { return { mutant: $m.name, applied: true, matches: 1, lost: [], own: false, error: ($r.stderr | str substring 0..<400) } }
        let rows = ($r.stdout | lines | last | from nuon)
        { mutant: $m.name, applied: true, matches: 1, lost: ($rows | where {|x| not $x.ok } | get name), own: ($rows | where name == $m.fixture | get 0.ok | not $in) }
    })
    print ($rows | to nuon)
}
