use (path self ../../../../../jab/nu/mod/nutype)

# The models of jab-stress-data's records, by file name
const TYPES = path self ../../../type/data
# The consumer table: each reader's required inputs, by pattern
const CONSUMERS = path self ../../../nuon/runner/record/consumers.nuon
# The consumer table's model
const CONSUMER_TYPE = path self ../../../type/runner/record/Consumer.nutype
# The classes a run's file takes, the landing's class table's
const ROLES = [log stream record picture build source fixture asset]
# What becomes of an original artifact
const DISPOSITIONS = [kept archived derived hash-only]
# The dispositions whose originals a stored object carries
const HELD = [kept archived]
# The dispositions an original may be absent from a restoration under
const ABSENT = [derived hash-only]
# The kinds of a stored object
const KINDS = [raw container archive]
# Where a part of a run ran, at schema 2
const SOURCES = [checkout export synthetic]
# Where a part of a run ran, at schema 1
const CHECKOUTS = [jab synthetic]
# How the retention rule keeps a run
const KEPT = [current last checkpoint targeted]
# How much of its set a run took
const SCOPES = [whole targeted]
# The files a landed run holds beside its stored objects
const CONTROL = [run.nuon inventory.nuon storage.nuon]
# An export part's record of the export it ran
const EXPORT_FIELDS = [name commit provenance symbols image_sha256 kernel_sha256]
# A restoration's receipt, beside the tree it lays out
const RECEIPT = "restoration.nuon"
# The restored tree in a restoration's directory
const TREE = "tree"

# A value's problems against a model of TYPES, each named with what it is
def model-problems [value: any, model: string, what: string]: nothing -> list<string> {
    let file = ($TYPES | path join $model)
    nutype problems $value (open --raw $file | decode utf-8) $file | each {|p| $"($what): ($p)" }
}

# A file's NUON, or null where it is missing or does not parse
def read-nuon [file: path]: nothing -> any {
    if ($file | path type) != "file" { return null }
    try { open --raw $file | decode utf-8 | from nuon } catch { null }
}

# A file's length and SHA-256, from its raw bytes
def measured [file: path]: nothing -> record<length: int, sha256: string> {
    let b = (open --raw $file | into binary)
    { length: ($b | bytes length), sha256: ($b | hash sha256) }
}

# Every file under a directory, by its path relative to it
def files-under [dir: path]: nothing -> list<string> {
    glob ($dir | path join "**" "*") --no-dir | each {|f| $f | path relative-to $dir } | sort
}

# A run record's schema: 1 where it names none, else the one it names
export def schema-of [run: record]: nothing -> any {
    $run | get -o schema | default 1
}

# A run record's meaning held: its scope, its keeping, its parts' sources
def run-semantics [run: record, schema: int]: nothing -> list<string> {
    let scope = (if $run.scope.kind in $SCOPES { [] } else { [$"run.nuon: scope.kind ($run.scope.kind) is none of ($SCOPES | str join ', ')"] })
    let counts = (if $run.scope.ran <= $run.scope.of { [] } else { [$"run.nuon: scope.ran ($run.scope.ran) past scope.of ($run.scope.of)"] })
    let kept = (if $run.kept.as in $KEPT { [] } else { [$"run.nuon: kept.as ($run.kept.as) is none of ($KEPT | str join ', ')"] })
    let parts = (if $schema == 1 {
        $run.builds | where {|b| $b.checkout not-in $CHECKOUTS } | each {|b| $"run.nuon: part ($b.part)'s checkout ($b.checkout) is none of ($CHECKOUTS | str join ', ')" }
    } else {
        let sources = ($run.builds | where {|b| $b.source not-in $SOURCES } | each {|b| $"run.nuon: part ($b.part)'s source ($b.source) is none of ($SOURCES | str join ', ')" })
        let exports = ($run.builds | where {|b| $b.source == "export" and ($b | get -o export) == null } | each {|b| $"run.nuon: part ($b.part) ran on an export and names no export's provenance" })
        $sources ++ $exports
    })
    $scope ++ $counts ++ $kept ++ $parts
}

# An inventory's meaning held: its paths once, roles, dispositions, reasons
def inventory-problems [inventory: list<any>]: nothing -> list<string> {
    let twice = ($inventory | get path | uniq --repeated | each {|p| $"inventory.nuon: ($p) listed more than once" })
    let roles = ($inventory | where {|r| $r.role not-in $ROLES } | each {|r| $"inventory.nuon: ($r.path)'s role ($r.role) is none of ($ROLES | str join ', ')" })
    let fates = ($inventory | where {|r| $r.disposition not-in $DISPOSITIONS } | each {|r| $"inventory.nuon: ($r.path)'s disposition ($r.disposition) is none of ($DISPOSITIONS | str join ', ')" })
    let reasons = ($inventory | where {|r| $r.disposition in $ABSENT and ($r.reason | str trim) == "" } | each {|r| $"inventory.nuon: ($r.path) is ($r.disposition) and gives no reason" })
    $twice ++ $roles ++ $fates ++ $reasons
}

# A storage's meaning held against the run's files and its inventory
def storage-problems [dir: path, storage: list<any>, inventory: list<any>]: nothing -> list<string> {
    let twice = ($storage | get object | uniq --repeated | each {|o| $"storage.nuon: ($o) listed more than once" })
    let kinds = ($storage | where {|s| $s.kind not-in $KINDS } | each {|s| $"storage.nuon: ($s.object)'s kind ($s.kind) is none of ($KINDS | str join ', ')" })
    let objects = ($storage | each {|s|
        let file = ($dir | path join $s.object)
        if ($file | path type) != "file" { $"storage.nuon: ($s.object) is not in the run" } else {
            let m = (measured $file)
            if $m.length != $s.length or $m.sha256 != $s.sha256 { $"storage.nuon: ($s.object) is ($m.length) bytes at SHA-256 ($m.sha256), where storage names ($s.length) at ($s.sha256)" }
        }
    } | compact)
    let shapes = ($storage | each {|s|
        let n = ($s.holds | length)
        match $s.kind {
            "raw" => (if $s.holds != [$s.object] { $"storage.nuon: raw ($s.object) holds ($s.holds | to nuon), where a raw object holds itself" }),
            "container" => (if $n != 1 or $s.object != $"($s.holds | get -o 0).nuonl" { $"storage.nuon: container ($s.object) holds ($s.holds | to nuon), where a container holds its one original" }),
            _ => (if $n == 0 { $"storage.nuon: archive ($s.object) holds nothing" }),
        }
    } | compact)
    let carriers = ($storage | each {|s| $s.holds | each {|h| { path: $h, object: $s.object } } } | flatten)
    let listed = ($inventory | get path)
    let strays = ($carriers | where {|c| $c.path not-in $listed } | each {|c| $"storage.nuon: ($c.object) holds ($c.path), which the inventory does not list" })
    let held = ($inventory | where {|r| $r.disposition in $HELD } | each {|r|
        let n = ($carriers | where path == $r.path | length)
        if $n != 1 { $"inventory.nuon: ($r.path) is ($r.disposition) and ($n) stored objects carry it, where one does" }
    } | compact)
    let gone = ($inventory | where disposition == "hash-only" | where {|r| $carriers | any {|c| $c.path == $r.path } } | each {|r| $"inventory.nuon: ($r.path) is hash-only and a stored object carries it" })
    let misheld = ($inventory | where {|r| $r.disposition in $HELD } | each {|r|
        let c = ($storage | where {|s| $r.path in $s.holds })
        if ($c | length) == 1 and (($r.disposition == "archived") != (($c | get 0.kind) == "archive")) { $"inventory.nuon: ($r.path) is ($r.disposition) and the ($c | get 0.kind) ($c | get 0.object) carries it" }
    } | compact)
    let members = ($storage | where kind == "archive" | each {|s|
        let file = ($dir | path join $s.object)
        if ($file | path type) == "file" {
            let listed = (do { ^tar --list --xz --file $file } | complete)
            let want = ($inventory | where {|r| $r.path in $s.holds } | get sha256 | uniq | sort)
            if $listed.exit_code != 0 { $"storage.nuon: archive ($s.object) does not list: ($listed.stderr | str trim)" } else if ($listed.stdout | lines | sort) != $want { $"storage.nuon: archive ($s.object)'s members are not its originals' SHA-256s, one each" }
        }
    } | compact)
    let named = ($storage | get object)
    let unnamed = (files-under $dir | where {|f| $f not-in $CONTROL and $f not-in $named } | each {|f| $"the run holds ($f), which storage.nuon does not name" })
    $twice ++ $kinds ++ $objects ++ $shapes ++ $strays ++ $held ++ $gone ++ $misheld ++ $members ++ $unnamed
}

# The repository holding a run: the one given, else the one its runs/ sits in
def root-of [dir: path, root: string]: nothing -> any {
    if $root != "" { return ($root | path expand) }
    let up = ($dir | path dirname | path dirname | path dirname)
    if ($up | path basename) == "runs" { $up | path dirname } else { null }
}

# A stored original's bytes, raw or an archive's member, null for any other
def original-of [dir: path, row: record, storage: list<any>]: nothing -> any {
    let s = ($storage | where {|x| $row.path in $x.holds } | get -o 0)
    if $s == null { return null }
    let file = ($dir | path join $s.object)
    match $s.kind {
        "raw" => (open --raw $file | into binary),
        "archive" => (^tar --extract --xz --to-stdout --file $file $row.sha256 | into binary),
        _ => null,
    }
}

# Each export part held to its provenance: present, its commit, symbols, and image
def export-problems [dir: path, root: any, run: record, inventory: list<any>, storage: list<any>]: nothing -> list<string> {
    $run.builds | where source == "export" | each {|b|
        let e = ($b | get -o export | default {})
        let lacking = ($EXPORT_FIELDS | where {|f| $f not-in ($e | columns) })
        if ($lacking | is-not-empty) { return [$"run.nuon: part ($b.part)'s export names no ($lacking | str join ', ')"] }
        let row = ($inventory | where path == $e.provenance | get -o 0)
        let elsewhere = (if $root == null { null } else { $root | path join $e.provenance })
        let bytes = (if $row != null and $row.disposition in $HELD { original-of $dir $row $storage } else if $elsewhere != null and ($elsewhere | path type) == "file" { open --raw $elsewhere | into binary } else { null })
        if $bytes == null { return [$"run.nuon: part ($b.part)'s provenance ($e.provenance) is stored neither in the run nor in this repository"] }
        let p = (try { $bytes | decode utf-8 | from nuon } catch { null })
        if $p == null { return [$"run.nuon: part ($b.part)'s provenance ($e.provenance) does not parse"] }
        let image = ($p | get -o image_sha256 | default ($p | get -o elf_sha256))
        [
            (if ($p | get -o commit) != $e.commit { $"run.nuon: part ($b.part)'s export commit ($e.commit) is not its provenance's, ($p | get -o commit | default 'none')" })
            (if ($p | get -o symbols | default []) != $e.symbols { $"run.nuon: part ($b.part)'s export symbols ($e.symbols | to nuon) are not its provenance's, ($p | get -o symbols | to nuon)" })
            (if $image != $e.image_sha256 { $"run.nuon: part ($b.part)'s export image ($e.image_sha256) is not its provenance's, ($image | default 'none')" })
        ] | compact
    } | flatten
}

# A landed run's problems, none where it holds: its record, inventory, storage, files
#
# `root` is the repository a provenance path outside the run is read from, by
# default the one the run sits in.
export def stored [run: path, --root: string = ""]: nothing -> list<string> {
    let dir = ($run | path expand)
    let record = (read-nuon ($dir | path join "run.nuon"))
    if $record == null { return [$"($dir) holds no run.nuon that parses"] }
    let schema = (schema-of $record)
    if $schema not-in [1 2] { return [$"run.nuon: schema ($schema), where the reader reads 1 and 2"] }
    if $schema == 1 {
        let shape = (model-problems $record "RunSchemaOne.nutype" "run.nuon")
        if ($shape | is-not-empty) { return $shape }
        return (run-semantics $record 1)
    }
    let shape = (model-problems $record "Run.nutype" "run.nuon")
    if ($shape | is-not-empty) { return $shape }
    let semantics = (run-semantics $record 2)
    let bound = ([[name, file, sha]; ["inventory.nuon" ($dir | path join "inventory.nuon") $record.inventory] ["storage.nuon" ($dir | path join "storage.nuon") $record.storage]] | each {|x|
        if ($x.file | path type) != "file" { $"($x.name) is missing" } else {
            let m = (measured $x.file)
            if $m.sha256 != $x.sha { $"($x.name) has SHA-256 ($m.sha256), where run.nuon names ($x.sha)" }
        }
    } | compact)
    if ($bound | is-not-empty) { return ($semantics ++ $bound) }
    let inventory = (read-nuon ($dir | path join "inventory.nuon"))
    let storage = (read-nuon ($dir | path join "storage.nuon"))
    let shapes = ((model-problems $inventory "Inventory.nutype" "inventory.nuon") ++ (model-problems $storage "Storage.nutype" "storage.nuon"))
    if ($shapes | is-not-empty) { return ($semantics ++ $shapes) }
    let exports = (export-problems $dir (root-of $dir $root) $record $inventory $storage)
    $semantics ++ (inventory-problems $inventory) ++ (storage-problems $dir $storage $inventory) ++ $exports
}

# A restoration's problems, none where it holds: its receipt against its run
export def restored [dir: path]: nothing -> list<string> {
    let dir = ($dir | path expand)
    let receipt = (read-nuon ($dir | path join $RECEIPT))
    if $receipt == null { return [$"($dir) holds no ($RECEIPT) that parses"] }
    let shape = (model-problems $receipt "Restoration.nutype" $RECEIPT)
    if ($shape | is-not-empty) { return $shape }
    let run = ($receipt.run | path expand)
    let record = (read-nuon ($run | path join "run.nuon"))
    if $record == null { return [$"the receipt's run, ($run), holds no run.nuon that parses"] }
    let tree = ($dir | path join $TREE)
    let laid = ($receipt.restored | each {|r|
        let file = ($tree | path join $r.path)
        if ($file | path type) != "file" { $"($r.path) is restored in the receipt and absent from the tree" } else if (measured $file).sha256 != $r.sha256 { $"($r.path) in the tree is not the SHA-256 the receipt names" }
    } | compact)
    let extra = (files-under $tree | where {|f| $f not-in ($receipt.restored | get path) } | each {|f| $"the tree holds ($f), which the receipt does not restore" })
    if (schema-of $record) == 1 {
        let named = ([$receipt.inventory_sha256 $receipt.storage_sha256] | compact | each {|_| "the receipt names an inventory or a storage for a run of schema 1, which has neither" })
        let copied = ($receipt.restored | each {|r|
            let file = ($run | path join $r.path)
            if ($file | path type) != "file" { $"($r.path) is restored and the run holds no such file" } else if (measured $file).sha256 != $r.sha256 { $"($r.path) is restored at a SHA-256 the run's file does not have" }
        } | compact)
        let missed = (files-under $run | where {|f| $f != "run.nuon" and $f not-in ($receipt.restored | get path) } | each {|f| $"the run's ($f) is not restored" })
        return ($laid ++ $extra ++ $named ++ $copied ++ $missed)
    }
    let sums = ([[name, file, wanted, receipt]; ["inventory" ($run | path join "inventory.nuon") $record.inventory $receipt.inventory_sha256] ["storage" ($run | path join "storage.nuon") $record.storage $receipt.storage_sha256]] | each {|x|
        if $x.receipt != $x.wanted { $"the receipt names the ($x.name) at ($x.receipt | default 'none'), where the run's record names ($x.wanted)" } else if (measured $x.file).sha256 != $x.wanted { $"the run's ($x.name) is not the SHA-256 its record names" }
    } | compact)
    let inventory = (read-nuon ($run | path join "inventory.nuon") | default [])
    let rows = ($receipt.restored | each {|r|
        let row = ($inventory | where path == $r.path | get -o 0)
        if $row == null { $"($r.path) is restored and the inventory does not list it" } else if $row.sha256 != $r.sha256 { $"($r.path) is restored at SHA-256 ($r.sha256), where the inventory lists ($row.sha256)" }
    } | compact)
    let absent = ($receipt.absent | where {|a| $a.disposition not-in $ABSENT } | each {|a| $"($a.path) is absent as ($a.disposition), where only a derived or hash-only original may be" })
    let unrestored = ($inventory | where {|r| $r.disposition in $HELD and $r.path not-in ($receipt.restored | get path) } | each {|r| $"($r.path) is ($r.disposition) and not restored" })
    $laid ++ $extra ++ $sums ++ $rows ++ $absent ++ $unrestored
}

# A reader's required inputs a restoration lacks, each named
export def required [dir: path, reader: string]: nothing -> list<string> {
    let table = (open --raw $CONSUMERS | decode utf-8 | from nuon)
    let shape = (nutype problems $table (open --raw $CONSUMER_TYPE | decode utf-8) $CONSUMER_TYPE)
    if ($shape | is-not-empty) { error make {msg: $"($CONSUMERS) breaks its model: ($shape | str join '; ')"} }
    let rows = ($table | where reader == $reader)
    if ($rows | is-empty) { return [$"the consumer table names no reader ($reader)"] }
    let tree = ($dir | path expand | path join $TREE)
    $rows | where {|r| glob ($tree | path join $r.pattern) --no-dir | is-empty } | each {|r| $"($reader) requires ($r.input), ($r.pattern), which the restoration lacks" }
}
