use (path self ../record)
use (path self ../log)

# The data checkout beside the workbench
const DATA = (path self ../../../../../jab-stress-data | path expand)

# The files a landed run holds beside its stored objects
const CONTROL = [run.nuon inventory.nuon storage.nuon]

# A file's length and SHA-256, from its raw bytes
def measured [file: path]: nothing -> record<length: int, sha256: string> {
    let b = (open --raw $file | into binary)
    { length: ($b | bytes length), sha256: ($b | hash sha256) }
}

# Every file under a directory, by its path relative to it
def files-under [dir: path]: nothing -> list<string> {
    glob ($dir | path join "**" "*") --no-dir | each {|f| $f | path relative-to $dir } | sort
}

# A file's class by its name, the landing's class table: its role and landing
def class-of [file: path]: nothing -> record<role: string, lands: string> {
    let name = ($file | path basename)
    let ext = ($file | path parse | get extension)
    if $name in [flags home] { return { role: record, lands: raw } }
    if ($name =~ '\.jabstage\.[A-Za-z0-9]+$') { return { role: fixture, lands: raw } }
    match $ext {
        "log" | "stdout" | "stderr" | "txt" | "nm" | "disas" => { role: log, lands: container }
        "out" | "in" | "wrpl" | "wav" => { role: stream, lands: raw }
        "nuon" | "nuonl" | "toml" => { role: record, lands: raw }
        "ppm" | "png" => { role: picture, lands: raw }
        "jab" | "elf" | "romfs" | "bin" => { role: build, lands: raw }
        "nu" => { role: source, lands: raw }
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
    match ($path | path parse | get extension) { "stdout" => "stdout", "stderr" => "stderr", _ => "file" }
}

# The landed run's objects written, each checked against its original
def landed [src: path, dest: path, classed: list<record>, producer: string]: nothing -> record<inventory: list<record>, storage: list<record>> {
    mut inventory = []
    mut storage = []
    for c in $classed {
        let from = ($src | path join $c.path)
        let orig = (measured $from)
        let object = (if $c.lands == container { $"($c.path).nuonl" } else { $c.path })
        let to = ($dest | path join $object)
        mkdir ($to | path dirname)
        if $c.lands == container {
            log wrap $from $to (source-of $c.path $producer) (stream-of $c.path)
            if ((log original $to | hash sha256) != $orig.sha256) { error make { msg: $"($c.path)'s container does not give back its bytes" } }
        } else {
            cp $from $to
            if ((measured $to).sha256 != $orig.sha256) { error make { msg: $"($c.path)'s copy is not its SHA-256" } }
        }
        let stored = (measured $to)
        $inventory = ($inventory | append { path: $c.path, role: $c.role, length: $orig.length, sha256: $orig.sha256, disposition: kept, reason: "" })
        $storage = ($storage | append { object: $object, kind: (if $c.lands == container { "container" } else { "raw" }), length: $stored.length, sha256: $stored.sha256, holds: [$c.path] })
    }
    { inventory: $inventory, storage: $storage }
}

# A run's directory landed in the data checkout, each log a container, checked
export def land [dir: path, subject: string, set: string, stamp: string, manifest: path, --data: string = "", --source: string = ""]: nothing -> record {
    let src = ($dir | path expand)
    let root = (if $data == "" { $DATA } else { $data | path expand })
    let dest = ($root | path join runs $subject $set $stamp)
    if ($dest | path exists) { error make { msg: $"($dest) exists; a run lands once" } }
    let given = (open --raw $manifest | decode utf-8 | from nuon)
    let entries = (files-under $src | each {|f| { path: $f, type: ($src | path join $f | path type) } })
    let links = ($entries | where type == symlink | get path)
    if ($links | is-not-empty) { error make { msg: $"the landing refuses ($links | str join ', '), a link where a run's record holds files" } }
    let wires = ($entries | where {|e| $e.type not-in [file symlink] } | get path)
    let classed = ($entries | where type == file | each {|e| { path: $e.path } | merge (class-of ($src | path join $e.path)) })
    let refused = ($classed | where lands == refused | each {|c| if $c.role == control { $"($c.path), a control file, its launch's cleanup incomplete" } else { $"($c.path), of no class the landing knows" } })
    if ($refused | is-not-empty) { error make { msg: $"the landing refuses ($refused | str join '; ')" } }
    let objects = ($classed | each {|c| if $c.lands == container { $"($c.path).nuonl" } else { $c.path } })
    let clashes = ($objects | uniq --repeated | append ($objects | where {|o| $o in $CONTROL }))
    if ($clashes | is-not-empty) { error make { msg: $"the landing's objects clash: ($clashes | str join ', ')" } }
    let producer = (if $source == "" { $set } else { $source })
    mkdir $dest
    try {
        let rows = (landed $src $dest $classed $producer)
        $rows.inventory | to nuon --indent 1 | save -f ($dest | path join inventory.nuon)
        $rows.storage | to nuon --indent 1 | save -f ($dest | path join storage.nuon)
        let run = ({ schema: 2, set: $set, stamp: $stamp } | merge ($given | select task scope builds kept) | merge {
            inventory: (measured ($dest | path join inventory.nuon)).sha256
            storage: (measured ($dest | path join storage.nuon)).sha256
        })
        $run | to nuon --indent 1 | save -f ($dest | path join run.nuon)
        let problems = (record stored $dest)
        if ($problems | is-not-empty) { error make { msg: $"the landed run breaks its record: ($problems | str join '; ')" } }
        { run: $dest, originals: ($rows.inventory | length), containers: ($classed | where lands == container | length), wires: $wires }
    } catch {|e|
        rm -r $dest
        error make { msg: $e.msg }
    }
}

# A schema 2 run's kept originals laid out under `tree`, each checked
def laid [run: path, tree: path, inventory: list<record>, storage: list<record>]: nothing -> list<record> {
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
            error make { msg: $"($row.path) is in ($s.kind) ($s.object), which no restore takes before the archives come" }
        }
        let got = (measured $to).sha256
        if $got != $row.sha256 { error make { msg: $"($row.path) restores at SHA-256 ($got), where the inventory lists ($row.sha256)" } }
        $restored = ($restored | append { path: $row.path, sha256: $got, object: $s.object })
    }
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
export def restore [run: path, scratch: path]: nothing -> record {
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
            let problems = (record stored $run)
            if ($problems | is-not-empty) { error make { msg: $"($run) breaks its record: ($problems | str join '; ')" } }
            let inventory = (open --raw ($run | path join inventory.nuon) | decode utf-8 | from nuon)
            let storage = (open --raw ($run | path join storage.nuon) | decode utf-8 | from nuon)
            let absent = ($inventory | where {|r| $r.disposition in [derived hash-only] } | each {|r| { path: $r.path, disposition: $r.disposition } })
            { run: $run, inventory_sha256: $manifest.inventory, storage_sha256: $manifest.storage, restored: (laid $run $tree $inventory $storage), absent: $absent }
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
    $ran.stdout | save --raw -f ($own | path join reread.stdout)
    $ran.stderr | save --raw -f ($own | path join reread.stderr)
    let done = { run: ($run | path expand), reader: $reader, bin: $bin, words: $words, restoration: (measured ($dir | path join restoration.nuon)).sha256, exit: $ran.exit_code }
    $done | to nuon --indent 1 | save -f ($own | path join reread.nuon)
    $done
}
