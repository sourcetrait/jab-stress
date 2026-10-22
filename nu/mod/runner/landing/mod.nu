use (path self ../record)
use (path self ../log)
use (path self ../../../../../jab/nu/mod/identity)

# The data checkout beside the workbench
const DATA = (path self ../../../../../jab-stress-data | path expand)

# The workbench's checkout and jab's beside it, a reread's reader's code
const READERS = [(path self ../../../.. | path expand) (path self ../../../../../jab | path expand)]

# The files a landed run holds beside its stored objects
const CONTROL = [run.nuon inventory.nuon storage.nuon]

# A run's archive: each archived original once by content, named by its SHA-256
const ARCHIVE = "archive.tar.xz"

# The archive's staging inside a landing run, removed before the run is held
const STAGING = ".staging"

# What retention makes of an original
const DISPOSITIONS = [kept archived derived hash-only]

# The dispositions whose originals the run does not store
const UNSTORED = [derived hash-only]

# xz's preset and threads for an archive
const XZ = "-6 -T0"

# A file's length and SHA-256, from its raw bytes
def measured [file: path]: nothing -> record<length: int, sha256: string> {
    let b = (open --raw $file | into binary)
    { length: ($b | bytes length), sha256: ($b | hash sha256) }
}

# Every file under a directory, by its path relative to it
def files-under [dir: path]: nothing -> list<string> {
    glob ($dir | path join "**" "*") --no-dir | each {|f| $f | path relative-to $dir } | sort
}

# Every entry under a directory but its directories, by its path under a prefix
def entries-of [root: path, prefix: string]: nothing -> list<record<path: string, from: string, type: string>> {
    glob ($root | path join "**" "*") | where {|p| ($p | path type) != "dir" } | each {|p|
        let rel = ($p | path relative-to $root)
        { path: (if $prefix == "" { $rel } else { $prefix | path join $rel }), from: $p, type: ($p | path type) }
    } | sort-by path
}

# A file's class by its name, the landing's class table: its role and landing
def class-of [file: path]: nothing -> record<role: string, lands: string> {
    let name = ($file | path basename)
    let ext = ($file | path parse | get extension)
    if $name in [flags home] { return { role: record, lands: raw } }
    if $name in [name title] and ($file | path dirname | path basename) == "map" { return { role: asset, lands: raw } }
    if ($name =~ '\.jabstage\.[A-Za-z0-9]+$') { return { role: fixture, lands: raw } }
    match $ext {
        "log" | "stdout" | "stderr" | "err" | "txt" | "nm" | "disas" => { role: log, lands: container }
        "out" | "in" | "wrpl" | "wav" => { role: stream, lands: raw }
        "nuon" | "nuonl" | "toml" => { role: record, lands: raw }
        "ppm" | "png" => { role: picture, lands: raw }
        "jab" | "elf" | "romfs" | "bin" | "o" => { role: build, lands: raw }
        "nu" | "S" | "inc" | "ld" | "tar" => { role: source, lands: raw }
        "map" | "pcm" | "mid" | "svg" => { role: asset, lands: raw }
        "json" => { role: control, lands: refused }
        _ => (if (open --raw $file | bytes at 0..<4) == 0x[7f 45 4c 46] { { role: build, lands: raw } } else { { role: unknown, lands: refused } })
    }
}

# A log's producer by its name: the guest's, QEMU's, the shim's, or the run's
def source-of [path: string, run: string]: nothing -> string {
    let name = ($path | path basename)
    if $name in [serial.log debug.log] { "guest" } else if $name == "qemu.log" or ($name | str ends-with "trace.log") { "qemu" } else if ($name | str ends-with "sdl.log") { "shim" } else { $run }
}

# A log's stream by its name: a command's stdout or stderr, else a file
def stream-of [path: string]: nothing -> string {
    match ($path | path parse | get extension) { "stdout" => "stdout", "stderr" | "err" => "stderr", _ => "file" }
}

# An original's disposition by the retention rules, the first that matches
def disposition-of [path: string, rules: list<any>]: nothing -> record<disposition: string, reason: string> {
    let hit = ($rules | where {|r| $path =~ $r.match } | get -o 0)
    if $hit == null { { disposition: kept, reason: "" } } else { { disposition: $hit.disposition, reason: ($hit | get -o reason | default "") } }
}

# The entries classed and disposed, every refusal named; committed ones flagged
def classify [entries: list<record>, rules: list<any>, committed: list<string>]: nothing -> list<record> {
    let links = ($entries | where type == symlink | get path)
    if ($links | is-not-empty) { error make { msg: $"the landing refuses ($links | str join ', '), a link where a run's record holds files" } }
    let classed = ($entries | where type == file | each {|e|
        $e | merge (class-of $e.from) | merge (disposition-of $e.path $rules) | insert committed ($e.path in $committed)
    })
    let refused = ($classed | where lands == refused | each {|c| if $c.role == control { $"($c.path), a control file, its launch's cleanup incomplete" } else { $"($c.path), of no class the landing knows" } })
    if ($refused | is-not-empty) { error make { msg: $"the landing refuses ($refused | str join '; ')" } }
    let unknown = ($classed | where {|c| $c.disposition not-in $DISPOSITIONS } | each {|c| $"($c.path) as ($c.disposition)" })
    if ($unknown | is-not-empty) { error make { msg: $"retention names no such disposition: ($unknown | str join '; ')" } }
    let unreasoned = ($classed | where {|c| $c.disposition in $UNSTORED and ($c.reason | str trim) == "" } | get path)
    if ($unreasoned | is-not-empty) { error make { msg: $"retention gives no reason for ($unreasoned | str join ', ')" } }
    $classed
}

# A kept original's stored object: a log landing now is a container, else itself
def object-of [c: record]: nothing -> string {
    if $c.lands == container and not $c.committed { $"($c.path).nuonl" } else { $c.path }
}

# The stored objects' names held apart from one another and from the run's records
def clashes [classed: list<record>]: nothing -> nothing {
    let kept = ($classed | where disposition == kept | each {|c| object-of $c })
    let objects = (if ($classed | any {|c| $c.disposition == archived }) { $kept | append $ARCHIVE } else { $kept })
    let clash = ($objects | uniq --repeated | append ($objects | where {|o| $o in ($CONTROL | append $STAGING) }))
    if ($clash | is-not-empty) { error make { msg: $"the landing's objects clash: ($clash | str join ', ')" } }
}

# The archived originals written into the run's archive, once each by content
def archive-write [rows: list<record>, dest: path]: nothing -> record {
    let stage = ($dest | path join $STAGING)
    mkdir ($stage | path join members)
    let unique = ($rows | uniq-by sha256)
    for r in $unique {
        let to = ($stage | path join members $r.sha256)
        cp $r.from $to
        if (measured $to).sha256 != $r.sha256 { error make { msg: $"($r.path)'s staged copy is not its SHA-256" } }
    }
    let names = ($unique | get sha256 | sort)
    let list = ($stage | path join members.txt)
    $names | str join (char nl) | $in + (char nl) | save -f $list
    let file = ($dest | path join $ARCHIVE)
    with-env { XZ_OPT: $XZ } {
        ^tar --create --xz --file $file --directory ($stage | path join members) --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner --files-from $list
    }
    let listed = (^tar --list --xz --file $file | lines | sort)
    if $listed != $names { error make { msg: $"($ARCHIVE) does not list exactly its ($names | length) members" } }
    rm -r $stage
    let m = (measured $file)
    { object: $ARCHIVE, kind: archive, length: $m.length, sha256: $m.sha256, holds: ($rows | get path) }
}

# The landed run's objects written, each checked against its original
def landed [dest: path, classed: list<record>, producer: string]: nothing -> record<inventory: list<record>, storage: list<record>> {
    mut inventory = []
    mut storage = []
    mut archived = []
    for c in $classed {
        let orig = (measured $c.from)
        $inventory = ($inventory | append { path: $c.path, role: $c.role, length: $orig.length, sha256: $orig.sha256, disposition: $c.disposition, reason: $c.reason })
        if $c.disposition == archived {
            $archived = ($archived | append { path: $c.path, sha256: $orig.sha256, from: $c.from })
        } else if $c.disposition == kept {
            let object = (object-of $c)
            let to = ($dest | path join $object)
            mkdir ($to | path dirname)
            if $object != $c.path {
                log container $c.from $to (source-of $c.path $producer) (stream-of $c.path)
                if ((log original $to | hash sha256) != $orig.sha256) { error make { msg: $"($c.path)'s container does not give back its bytes" } }
            } else {
                cp $c.from $to
                if ((measured $to).sha256 != $orig.sha256) { error make { msg: $"($c.path)'s copy is not its SHA-256" } }
            }
            let stored = (measured $to)
            $storage = ($storage | append { object: $object, kind: (if $object != $c.path { "container" } else { "raw" }), length: $stored.length, sha256: $stored.sha256, holds: [$c.path] })
        }
    }
    if ($archived | is-not-empty) { $storage = ($storage | append (archive-write $archived $dest)) }
    { inventory: $inventory, storage: $storage }
}

# The inventory, storage, and run record written, the run held to its record
def recorded [dest: path, rows: record, head: record, root: path]: nothing -> nothing {
    $rows.inventory | to nuon --indent 1 | save -f ($dest | path join inventory.nuon)
    $rows.storage | to nuon --indent 1 | save -f ($dest | path join storage.nuon)
    let sums = { inventory: (measured ($dest | path join inventory.nuon)).sha256, storage: (measured ($dest | path join storage.nuon)).sha256 }
    $head | merge $sums | to nuon --indent 1 | save -f ($dest | path join run.nuon)
    let problems = (record stored $dest --root $root)
    if ($problems | is-not-empty) { error make { msg: $"the landed run breaks its record: ($problems | str join '; ')" } }
}

# A run's directory landed in the data checkout, its archive and hashes, checked
export def land [dir: path, subject: string, set: string, stamp: string, manifest: path, --data: string = "", --source: string = ""]: nothing -> record {
    let src = ($dir | path expand)
    let root = (if $data == "" { $DATA } else { $data | path expand })
    let dest = ($root | path join runs $subject $set $stamp)
    if ($dest | path exists) { error make { msg: $"($dest) exists; a run lands once" } }
    let given = (open --raw $manifest | decode utf-8 | from nuon)
    let entries = (entries-of $src "")
    let classed = (classify $entries ($given | get -o retention | default []) [])
    clashes $classed
    mkdir $dest
    try {
        let rows = (landed $dest $classed (if $source == "" { $set } else { $source }))
        recorded $dest $rows ({ schema: 2, set: $set, stamp: $stamp } | merge ($given | select task scope builds kept)) $root
        {
            run: $dest, originals: ($rows.inventory | length), containers: ($rows.storage | where kind == container | length),
            archived: ($rows.inventory | where disposition == archived | length), unstored: ($rows.inventory | where {|r| $r.disposition in $UNSTORED } | length),
            wires: ($entries | where {|e| $e.type not-in [file symlink] } | get path),
        }
    } catch {|e|
        rm -r $dest
        error make { msg: $e.msg }
    }
}

# A schema 2 run's kept and archived originals laid out under `tree`, each checked
def laid [run: path, tree: path, inventory: list<record>, storage: list<record>, unpacked: path]: nothing -> list<record> {
    for a in ($storage | where kind == "archive") {
        mkdir $unpacked
        ^tar --extract --xz --file ($run | path join $a.object) --directory $unpacked
    }
    mut restored = []
    for row in ($inventory | where {|r| $r.disposition in [kept archived] }) {
        let s = ($storage | where {|x| $row.path in $x.holds } | first)
        let to = ($tree | path join $row.path)
        mkdir ($to | path dirname)
        if $s.kind == "raw" {
            cp ($run | path join $s.object) $to
        } else if $s.kind == "container" {
            log original ($run | path join $s.object) | save --raw -f $to
        } else {
            cp ($unpacked | path join $row.sha256) $to
        }
        let got = (measured $to).sha256
        if $got != $row.sha256 { error make { msg: $"($row.path) restores at SHA-256 ($got), where the inventory lists ($row.sha256)" } }
        $restored = ($restored | append { path: $row.path, sha256: $got, object: $s.object })
    }
    if ($unpacked | path exists) { rm -r $unpacked }
    $restored
}

# A schema 1 run's files copied under `tree` as they are
def copied [run: path, tree: path]: nothing -> list<record> {
    mut restored = []
    for f in (files-under $run | where {|f| $f != "run.nuon" }) {
        let to = ($tree | path join $f)
        mkdir ($to | path dirname)
        cp ($run | path join $f) $to
        $restored = ($restored | append { path: $f, sha256: (measured $to).sha256, object: $f })
    }
    $restored
}

# A landed run laid out as its runner wrote it, each original checked, a receipt
export def restore [run: path, scratch: path, --root: string = ""]: nothing -> record {
    let run = ($run | path expand)
    let out = ($scratch | path expand)
    if ($out | path exists) { error make { msg: $"($out) exists; a restoration is made once" } }
    let manifest = (open --raw ($run | path join run.nuon) | decode utf-8 | from nuon)
    let schema = (record schema-of $manifest)
    let tree = ($out | path join tree)
    mkdir $tree
    try {
        let receipt = (if $schema == 1 {
            { run: $run, inventory_sha256: null, storage_sha256: null, restored: (copied $run $tree), absent: [] }
        } else {
            let problems = (record stored $run --root $root)
            if ($problems | is-not-empty) { error make { msg: $"($run) breaks its record: ($problems | str join '; ')" } }
            let inventory = (open --raw ($run | path join inventory.nuon) | decode utf-8 | from nuon)
            let storage = (open --raw ($run | path join storage.nuon) | decode utf-8 | from nuon)
            let absent = ($inventory | where {|r| $r.disposition in $UNSTORED } | each {|r| { path: $r.path, disposition: $r.disposition } })
            { run: $run, inventory_sha256: $manifest.inventory, storage_sha256: $manifest.storage, restored: (laid $run $tree $inventory $storage ($out | path join unpacked)), absent: $absent }
        })
        $receipt | to nuon --indent 1 | save -f ($out | path join restoration.nuon)
        let problems = (record restored $out)
        if ($problems | is-not-empty) { error make { msg: $"the restoration breaks its receipt: ($problems | str join '; ')" } }
        { restoration: $out, restored: ($receipt.restored | length), absent: ($receipt.absent | length), schema: $schema }
    } catch {|e|
        rm -r $out
        error make { msg: $e.msg }
    }
}

# A landed run reread: restored, its reader's inputs held, its command run on it
export def reread [run: path, scratch: path, reader: string, bin: path, ...words: string]: nothing -> record {
    let out = ($scratch | path expand)
    if ($out | path exists) { error make { msg: $"($out) exists; a reread is made once" } }
    mkdir $out
    let dir = ($out | path join restoration)
    restore $run $dir | ignore
    let missing = (record required $dir $reader)
    if ($missing | is-not-empty) { error make { msg: $"the reread refuses: ($missing | str join '; ')" } }
    let own = ($out | path join out)
    mkdir $own
    let args = ($words | each {|w| $w | str replace --all '{tree}' ($dir | path join tree) | str replace --all '{out}' $own })
    let ran = (^$nu.current-exe $bin ...$args | complete)
    let taken = ([reread.stdout reread.stderr reread.nuon] | where {|f| $own | path join $f | path exists })
    if ($taken | is-not-empty) { error make { msg: $"the reader wrote ($taken | str join ', ') into its out, the names the reread keeps for its own record" } }
    $ran.stdout | save --raw -f ($own | path join reread.stdout)
    $ran.stderr | save --raw -f ($own | path join reread.stderr)
    let done = { run: ($run | path expand), reader: $reader, bin: $bin, words: $words, restoration: (measured ($dir | path join restoration.nuon)).sha256, exit: $ran.exit_code, identity: (identity reader $READERS) }
    $done | to nuon --indent 1 | save -f ($own | path join reread.nuon)
    $done
}

# The stored object carrying a run's original, null for one the run does not store
def carrier-of [path: string, storage: list<record>]: nothing -> any {
    $storage | where {|s| $path in $s.holds } | get -o 0.object
}

# A landed run of schema 1 moved to schema 2, its further originals, a receipt
export def migrate [run: path, manifest: path, scratch: path, --data: string = ""]: nothing -> record {
    let run = ($run | path expand)
    let root = (if $data == "" { $DATA } else { $data | path expand })
    let out = ($scratch | path expand)
    if ($out | path exists) { error make { msg: $"($out) exists; a migration is made once" } }
    let parts = ($run | path relative-to ($root | path join runs) | path split)
    if ($parts | length) != 3 { error make { msg: $"($run) is not a run of ($root)" } }
    let old = (open --raw ($run | path join run.nuon) | decode utf-8 | from nuon)
    if (record schema-of $old) != 1 { error make { msg: $"($run) is at schema (record schema-of $old), where a migration takes schema 1" } }
    let at = ($run | path relative-to $root)
    let status = (^git -C $root status --porcelain --untracked-files=all -- $at | complete)
    if $status.exit_code != 0 or ($status.stdout | str trim) != "" { error make { msg: $"($at) holds what git has not committed" } }
    let commit = (^git -C $root rev-parse HEAD | str trim)
    let given = (open --raw $manifest | decode utf-8 | from nuon)
    let withs = ($given | get -o with | default [])
    let committed = (entries-of $run "" | where path != "run.nuon")
    let named = ($committed | get path)
    let further = ($withs | each {|w| entries-of ($w.from | path expand) $w.to } | flatten)
    let shared = ($further | where {|f| $f.path in $named and $f.type == "file" })
    let differ = ($shared | where {|f| (measured $f.from).sha256 != (measured ($run | path join $f.path)).sha256 } | get path)
    if ($differ | is-not-empty) { error make { msg: $"the run and its further originals differ at ($differ | str join ', ')" } }
    let entries = ($committed ++ ($further | where {|f| $f.path not-in $named }))
    let classed = (classify $entries ($given | get -o retention | default []) $named)
    clashes $classed
    mkdir $out
    let dest = ($out | path join run)
    mkdir $dest
    let rows = (landed $dest $classed $parts.1)
    recorded $dest $rows ({ schema: 2, set: $parts.1, stamp: $parts.2 } | merge ($given | select task scope builds kept)) $root
    let back = (restore $dest ($out | path join restoration) --root $root)
    let aside = ($out | path join old)
    mv $run $aside
    try { mv $dest $run } catch {|e| mv $aside $run; error make { msg: $e.msg } }
    let stamp = (date now | date to-timezone UTC | format date "%Y%m%dT%H%M%S")
    let sources = ($classed | zip $rows.inventory | each {|p|
        let c = $p.0
        let r = $p.1
        {
            repository: (if $c.committed { "jab-stress-data" } else { null }), path: (if $c.committed { $at | path join $c.path } else { $c.from }),
            sha256: $r.sha256, bytes: $r.length, fate: { kind: $r.disposition, as: $c.path, to: (carrier-of $c.path $rows.storage) },
        }
    })
    let written = (files-under $run | each {|f|
        let m = (measured ($run | path join $f))
        let kind = (if $f in $CONTROL { "record" } else { $rows.storage | where object == $f | get -o 0.kind | default "unknown" })
        { repository: "jab-stress-data", path: ($at | path join $f), sha256: $m.sha256, bytes: $m.length, origin: { kind: $kind, phase: Landed } }
    })
    let receipt = {
        migration: $given.migration, stamp: $stamp, complete: true, run: $at,
        sources: ([{ repository: "jab-stress-data", commit: $commit, paths: [$at] }] ++ ($withs | each {|w| { repository: null, commit: null, paths: [($w.from | path expand)] } })),
        phases: [[phase, done]; [Classed, true] [Landed, true] [Restored, true] [Replaced, true]],
        checks: [
            { phase: Classed, check: "each further original equal by SHA-256 to the run's own file at its path", files: ($shared | length), ok: true }
            { phase: Landed, check: "the landed run held to its record by runner record stored", ok: true }
            { phase: Restored, check: "every kept and archived original restored at its inventory SHA-256 by runner restore", files: $back.restored, ok: true }
        ],
        source_files: $sources,
        destination_files: $written,
        counts: {
            sources: { files: ($sources | length), bytes: ($sources | get bytes | math sum), committed: ($classed | where committed | length) },
            dispositions: ($rows.inventory | group-by disposition | transpose disposition rows | each {|g| { disposition: $g.disposition, files: ($g.rows | length), bytes: ($g.rows | get length | math sum) } }),
            destinations: { files: ($written | length), bytes: ($written | get bytes | math sum) },
        },
    }
    let file = ($root | path join migration $"($stamp)-($given.migration | str lowercase).nuon")
    $receipt | to nuon --indent 1 | save $file
    rm -r $aside
    { run: $run, receipt: $file, originals: ($rows.inventory | length), archived: ($rows.inventory | where disposition == archived | length), unstored: ($rows.inventory | where {|r| $r.disposition in $UNSTORED } | length), restored: $back.restored }
}
