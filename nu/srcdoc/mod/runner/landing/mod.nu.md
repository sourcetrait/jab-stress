# mod.nu

A run's record into the data checkout and back out, by DataModels' three
representations: the landed run's stored objects held by its inventory and
storage, a restoration's originals by its receipt, and a reader's needs by the
consumer table. `runner record` validates each; this module makes them.

## const DATA

The data checkout beside the workbench, `../jab-stress-data`, where `land`
writes unless `--data` names another root, a scratch one for a trial.

## def class-of

The landing's class table, a file's class by its name: a log (`.log`,
`.stdout`, `.stderr`, `.txt`, `.nm`, `.disas`) lands as a container; a
stream (`.out`, `.in`, `.wrpl`, `.wav`), a record (`.nuon`, `.nuonl`,
`.toml`, `flags`, a build's `home`), a picture (`.ppm`, `.png`), a build
(`.jab`, `.elf`, `.romfs`, a flat `.bin`, or any file opening with ELF's
magic), a source (a copied `.nu`),
and a fixture (a staged `.jabstage.<nonce>`) land as written. A control
file (`.json`, a supervised launch's live wire) and any kind the table does
not list refuse the landing by name, so a new kind is classified on purpose.

## def source-of

A log container's producer: `guest` for `serial.log` and `debug.log`,
`qemu` for `qemu.log` and a `trace.log`, `shim` for an `sdl.log`, and
otherwise the run's own, its set unless `--source` names it.

## def land

`land <dir> <subject> <set> <stamp> <manifest>`: the layout's landing made
class-aware, into `runs/<subject>/<set>/<stamp>/`, which must not exist.
Regular files land. A pipe or a socket is a live wire holding no bytes at
rest, a plain launch's monitor, API, and pad pipes among them, and is left
out, named in the result's `wires`; reading one would wait on a writer that
has gone. A link refuses the landing by name.
`manifest` is a NUON file of the record's own fields, `task`, `scope`,
`builds` at schema 2 (each part's `source` and, for an export, its
provenance), and `kept`. Each log is wrapped and given back by the
container's reader to its source's SHA-256; each other file is copied and
held to its SHA-256; every object is measured as it lands; then
`inventory.nuon`, every original kept, `storage.nuon`, and `run.nuon` at
schema 2 naming both by SHA-256, and the whole held by `record stored`. A
failure removes the run it began. The retention rule's changes to the set's
other runs and the commit stay the lander's steps, as the layout note's
third and fourth are, since a prune turns on which documents still cite a
run.

## def restore

`restore <run> <scratch>`: the run laid out under `<scratch>/tree/` as its
runner wrote it, with `restoration.nuon` beside, the receipt `record
restored` holds. A schema 2 run is held by `record stored` first, then
every kept original is written back, a container's through its reader,
and held to its inventory row; a derived or hash-only original is listed
absent. A run committed before, schema 1, is copied, its files raw and its
receipt naming no inventory or storage. A damaged container, a mismatch,
or a kept original missing refuses the whole restore, and the scratch it
began is removed.

## def reread

`reread <run> <scratch> <reader> <bin> <words>`: the run restored into
`<scratch>/restoration`, the reader's required inputs held by `record
required`, then `nu <bin> <words>` run unchanged, `{tree}` in a word the
restored tree and `{out}` the reread's own directory, `<scratch>/out`,
which holds `reread.nuon` naming the run, the reader, the command, the
receipt's SHA-256, and the exit, beside the command's stdout and stderr. A
reread is a run of its own: `<scratch>/out` is what lands, its `why` naming
the run it read.
