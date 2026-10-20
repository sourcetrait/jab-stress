# Run records

The data checkout, `../jab-stress-data`, keeps each run's record. New runs
land with each text log wrapped in a container, read back through a
restoration; a run committed before stays as written and restores as a
copy. Three modules under `nu/mod/runner/` own it:

- `landing` makes the records: `land` writes a run into the data checkout,
  `restore` lays a landed run out again, and `reread` runs a reader over a
  restoration.
- `log` is the container, `Log.nutype`: a log's bytes whole in a `.nuonl`
  file, a header, chunks of 64 KiB at most, and a trailer with the length
  and the SHA-256.
- `record` is the one validator. Its models are in `nu/type/data/`: the
  manifest at schema 2 (`Run.nutype`) and at schema 1
  (`RunSchemaOne.nutype`), the inventory, the storage, a restoration's
  receipt, and a log container.

## Landing a run

```
nu nu/bin/nuance.nu runner land <dir> <subject> <set> <stamp> <manifest>
```

`<dir>` is the run's own directory as its runner left it, and `<manifest>`
a NUON file of the record's own fields: `task`, `scope`, `builds` (each
part's `part`, `build`, `source`, one of `checkout`, `export`, and
`synthetic`, an export's provenance beside it, and `record`), and `kept`.
The run lands at `runs/<subject>/<set>/<stamp>/`, which must not exist.
Each file is classed by its name: a log (`.log`, `.stdout`, `.stderr` and `.err`,
`.txt`, `.nm`, `.disas`) is wrapped as `<name>.nuonl`, and a stream, a
record, a picture, a build, a source, or a fixture is copied as written. A
control file or a kind the table does not list refuses the landing by
name. Every original and every stored object is measured and checked as it
lands, `inventory.nuon` and `storage.nuon` are written, `run.nuon` names
them by SHA-256 at schema 2, and the whole is held by `runner record
stored`. Then apply the layout's retention rule to the set's other runs
and commit, as `doc/notes/layout.md` in the data checkout says.

## Reading a landed run

```
nu nu/bin/nuance.nu runner restore <run> <scratch>
nu nu/bin/nuance.nu runner reread <run> <scratch> <reader> <bin> <words>
nu nu/bin/nuance.nu runner log text <container>
```

`restore` lays the run out under `<scratch>/tree/` as its runner wrote it,
every kept original held to its inventory row, with the receipt
`restoration.nuon` beside it. `reread` restores the run, holds the reader's
required inputs, and runs `nu <bin> <words>` with `{tree}` the restored tree
and `{out}` the reread's own directory, which holds `reread.nuon` and the
command's output, `reread.stdout` and `reread.stderr`, and is what lands as
the reread's run; a reader that writes one of those three names is refused.
Every consumer of landed data reads a restoration, never the data
checkout's files.

## Checking a record

```
nu nu/bin/nuance.nu runner record stored <run>
nu nu/bin/nuance.nu runner record restored <dir>
nu nu/bin/nuance.nu runner record required <dir> <reader>
```

Each lists its problems, one a line, and lists none where the record
holds.

- `stored` holds a landed run's directory whole. A manifest that names no
  schema is schema 1 and is held to its model and its meaning. A manifest
  at schema 2 is held to its model, its inventory and storage are bound to
  it by SHA-256, and every stored object, original, and file in the run is
  accounted for.
- `restored` holds a restoration to the run it was made from. The
  restoration's directory holds `restoration.nuon`, the receipt, and
  `tree/`, the run's files laid out as its runner wrote them.
- `required` names each input a reader needs that the restored tree lacks.
  The readers and their inputs are in `nu/nuon/runner/record/consumers.nuon`.

## What it expects

The SDK's `nutype` module in the Jab checkout beside this one, `../jab`,
which holds a value to a model. The rest is the run's own files.
