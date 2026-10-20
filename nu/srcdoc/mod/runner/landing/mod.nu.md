# mod.nu

A run's record into the data checkout and back out, by DataModels' three
representations: the landed run's stored objects held by its inventory and
storage, a restoration's originals by its receipt, and a reader's needs by the
consumer table. `runner record` validates each; this module makes them.
Retention, EvidenceRetention's, decides each original's disposition: kept
in the run, archived, derived, or kept as its hash alone.

## const DATA

The data checkout beside the workbench, `../jab-stress-data`, where `land`
and `migrate` write unless `--data` names another root, a scratch one for a
trial.

## const ARCHIVE

A run's archive, `archive.tar.xz`: every archived original once by its
content, the member named by its SHA-256, so byte-identical copies in a
run, a bundle's copies of its run's files among them, are stored once. The
inventory maps each original's path to its SHA-256 and so to its member.

## const STAGING

The archive's staging directory inside the run being landed, removed once
the archive is written and before the run is held, so a held run never
names it.

## const XZ

xz's preset and threads for an archive, `-6 -T0`. The archive's own bytes
are not reproducible across thread counts and need not be: its SHA-256 is
recorded where it lands, and its members are what a restore checks.

## def entries-of

Every entry under a tree but its directories, each with its path under a
prefix, the path it is read from, and its type, so files, links, and live
wires are told apart before anything is read.

## def class-of

The landing's class table, a file's class by its name: a log (`.log`,
`.stdout`, `.stderr`, `.txt`, `.nm`, `.disas`) lands as a container; a
stream (`.out`, `.in`, `.wrpl`, `.wav`), a record (`.nuon`, `.nuonl`,
`.toml`, `flags`, a build's `home`), a picture (`.ppm`, `.png`), a build
(`.jab`, `.elf`, `.romfs`, a flat `.bin`, an object `.o`, or any file
opening with ELF's magic), a source (a copied `.nu`, an export's `.S`,
`.inc`, and `.ld` sources and its `.tar` source archive), an asset (a map
tree's `.map`, `.pcm`, `.mid`, and `.svg` files and its `map/name` and
`map/title`), and a fixture (a staged `.jabstage.<nonce>`) land as written.
A control file (`.json`, a supervised launch's live wire) and any kind the
table does not list refuse the landing by name, so a new kind is classified
on purpose.

## def source-of

A log container's producer: `guest` for `serial.log` and `debug.log`,
`qemu` for `qemu.log` and a `trace.log`, `shim` for an `sdl.log`, and
otherwise the run's own, its set unless `--source` names it.

## def disposition-of

An original's disposition by the manifest's `retention`, a list of rules
`{match, disposition, reason}`, `match` a regular expression over the
run-relative path, the first rule that matches deciding; an original no
rule matches is kept.

## def classify

Every entry classed and disposed, every refusal named before anything is
written: a link, a control file, a kind of no class, a disposition other
than the four, and a derived or hash-only original whose rule gives no
reason. An entry the run already holds as committed is flagged, so it
stays as committed.

## def object-of

A kept original's stored object: a log landing now is a container, its
name with `.nuonl` added; a committed file, a log among them, stays the
file it was.

## def archive-write

The archived originals copied into the staging once each by SHA-256, each
copy checked, then written as one tar compressed by xz, its members sorted
by name, with no time or owner of their own, its listing held to the
members, and its storage row returned holding every archived path.

## def landed

Each original measured and listed in the inventory with its disposition; a
kept one stored, a log wrapped and given back by the container's reader to
its source's SHA-256, any other copied and held to its SHA-256; an archived
one gathered for the archive; a derived or hash-only one stored nowhere.

## def recorded

The inventory, the storage, and `run.nuon` at schema 2 naming both by
SHA-256, written, then the whole held by `record stored`, given the
repository root that a provenance path outside the run is read from.

## def land

`land <dir> <subject> <set> <stamp> <manifest>`: the layout's landing, into
`runs/<subject>/<set>/<stamp>/`, which must not exist. Regular files land.
A pipe or a socket is a live wire holding no bytes at rest, a plain
launch's monitor, API, and pad pipes among them, and is left out, named in
the result's `wires`; reading one would wait on a writer that has gone. A
link refuses the landing by name. `manifest` is a NUON file of the
record's own fields, `task`, `scope`, `builds` at schema 2, and `kept`,
and optionally `retention`. A failure removes the run it began. The
retention rule's changes to the set's other runs and the commit stay the
lander's steps, as the layout note's third and fourth are, since a prune
turns on which documents still cite a run.

## def laid

A schema 2 run's kept and archived originals written back under the tree:
each archive extracted once into the restoration's own `unpacked/`, then a
raw object copied, a container given back by its reader, and an archived
original copied from the member its SHA-256 names, each held to its
inventory row. The extraction is removed once the tree is laid.

## def restore

`restore <run> <scratch>`: the run laid out under `<scratch>/tree/` as its
runner wrote it, with `restoration.nuon` beside, the receipt `record
restored` holds. A schema 2 run is held by `record stored` first, `--root`
naming the repository for a provenance path outside the run, then every
kept and archived original is written back and held; a derived or
hash-only original is listed absent. A run committed before, schema 1, is
copied, its files raw and its receipt naming no inventory or storage. A
damaged container or archive, a mismatch, or a kept or archived original
missing refuses the whole restore, and the scratch it began is removed.

## def reread

`reread <run> <scratch> <reader> <bin> <words>`: the run restored into
`<scratch>/restoration`, the reader's required inputs held by `record
required`, then `nu <bin> <words>` run unchanged, `{tree}` in a word the
restored tree and `{out}` the reread's own directory, `<scratch>/out`,
which holds `reread.nuon` naming the run, the reader, the command, the
receipt's SHA-256, and the exit, beside the command's stdout and stderr as
`reread.stdout` and `reread.stderr`. Those three names are the reread's: a
reader that wrote one into its out is refused by name rather than
overwritten. A reread is a run of its own: `<scratch>/out` is what lands,
its `why` naming the run it read.

## def migrate

`migrate <run> <manifest> <scratch>`: a run committed at schema 1 moved to
schema 2, the layout's migration. The run must be one of the repository's,
at schema 1, with nothing git has not committed. `manifest` carries the new
record's fields, `retention`, `migration`, the receipt's WikiWord name, and
`with`, a list of `{from, to}`: a tree outside the repository holding more
of the run's originals, laid at `to` in the run. A further original at a
path the run already holds must equal it by SHA-256. Every committed file
stays as committed unless its rule disposes of it otherwise; the further
originals land by their dispositions. The new run is written into
`<scratch>/run`, held by `record stored`, restored whole into
`<scratch>/restoration`, and only then swapped into the run's place, the
old one moved aside and put back if the swap fails. The receipt,
`migration/<stamp>-<name>.nuon`, names the commit the run left and each
further tree, every original with its SHA-256, size, disposition, and the
object carrying it, every file the run now holds, the checks, and counts.
The commit is the lander's step.
