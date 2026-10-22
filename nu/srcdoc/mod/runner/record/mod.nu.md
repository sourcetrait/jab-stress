# mod.nu

The one validator of a run's record in jab-stress-data. Each check returns
its problems, a line each, and none where the record holds. A run's
records are held in three representations, each to its own record: the
landed run to its manifest, inventory, and storage; a restoration to its
receipt; and a reader's needs to the consumer table. Structure is the SDK's
`nutype problems` against the models in `nu/type/data/`; the meaning of a
field, which a model's types cannot say, is this module's own. A reader's
output is held to its own model as it lands (outputs).

## const TYPES

The models of the data repository's records, `Run.nutype` for a manifest of
schema 2, `RunSchemaOne.nutype` for one written before, and the inventory,
storage, restoration, and log container models beside them.

## const OUTPUTS

The output table, `nu/nuon/runner/record/outputs.nuon`: a row a reader's
output, its pattern relative to a run, the sets it lands in as
`<subject>/<set>` (none for every set, where the file's name is its
reader's alone), and its model, a path in the checkout the row's
`repository` names. Its model is `nu/type/runner/record/Output.nutype`
(OUTPUT_TYPE).

## const REPOSITORIES

The checkouts an output's model sits in: this workbench, `jab-stress`, and
jab beside it, `jab`, whose gauge writes `gauge.nuon`. A model sits beside
the module that writes its output, in the writer's own checkout.

## const ROLES

The classes the landing's class table gives a run's file, read from the
DataModels plan with EvidenceRetention's asset: a log, a stream, a record,
and a picture, build, source, fixture, or asset. A control file, such as a
supervised launch's JSON wire files, never reaches a landing, so it has no
role here.

## const EXPORT_FIELDS

An export part's record of the export it ran: its name, its source commit,
its provenance record's path, its symbols, its image's SHA-256, and the
kernel's ELF it ran with, null where it ran none or none was recorded.

## const DISPOSITIONS

What becomes of an original artifact: `kept`, stored in the run as raw
bytes or a container; `archived`, a member of the run's archive;
`derived`, regenerated from kept inputs by its named reader; and
`hash-only`, its SHA-256 kept and the original gone.

## const CONTROL

The files a landed run holds beside its payload. They sit outside the
payload they describe, so no record holds its own hash: the manifest names
the inventory's and the storage's SHA-256, and those two name the payload.

## const RECEIPT

A restoration's receipt sits beside the tree it lays out, at the top of the
restoration's directory, with the tree in `tree/`, so the tree holds the
run's own files and nothing else.

## def schema-of

A manifest that names no schema was written before schema 2 and is read as
schema 1, its `checkout` field keeping its meaning, `synthetic` covering a
candidate copy as the data layout defines it.

## def run-semantics

The meaning the models leave open: a scope's kind is whole or targeted and
it ran no more items than its set held; a run is kept as current, last,
checkpoint, or targeted; a part ran in the Jab checkout or in a synthetic
tree at schema 1, and in the checkout, an export, or a synthetic tree at
schema 2, where a part that ran on an export names the export's provenance.

## def inventory-problems

Each original once, its role one of the class table's, its disposition one
of the four, and a reason given wherever the original is derived or kept
as its hash alone.

## def storage-problems

Each stored object once, its kind raw, container, or archive, present in
the run at the length and SHA-256 the storage names; a raw object holding
itself, a container holding its one original at the original's name with
`.nuonl` added, an archive holding at least one; every original it holds
listed in the inventory; every kept or archived original carried by
exactly one object, an archived one by an archive and a kept one by a raw
object or a container; no hash-only original carried; an archive listing
exactly its originals' SHA-256s, one member each; and no file in the run
that the storage does not name, the three control files aside.

## def root-of

The repository a run sits in, read from its path when it lies at
`runs/<subject>/<set>/<stamp>`, unless one is given; a run laid out
elsewhere, a migration's new run in its scratch, is given its root.

## def original-of

A stored original's bytes: a raw object read as it is, an archived one as
its member, extracted to stdout by its SHA-256. A record lands raw, so a
container never holds a provenance and is not read here.

## def export-problems

Each part that ran on an export held to its provenance record: the export
names every field of EXPORT_FIELDS; the provenance is stored in the run,
or is a file of the repository at that path when the export's own run
holds it; it parses; and its commit, symbols, and image, a kernel export's
ELF where it records no image, are the export's.

## def stored

A landed run held whole. A schema the reader does not read is refused
before anything else. A run of schema 1 is held to its model and its
meaning alone, since it has no inventory or storage. A run of schema 2 is
held to its model, then its inventory and storage are bound to the
manifest by their SHA-256, held to their models, and held against each
other and against the files the run holds, and each export part against
its provenance. `--root` names the repository for a provenance outside the
run.

## def restored

A restoration held to the run it was made from: every file the receipt
restores is in the tree at its SHA-256, and the tree holds nothing else.
For a run of schema 1, which restores as a copy, the receipt names no
inventory or storage, every restored file is the run's own file at the
same SHA-256, and every file of the run but its manifest is restored. For a
run of schema 2, the receipt's inventory and storage are the run's by
SHA-256, every restored file is its inventory row's, only a derived or
hash-only original is absent, and every kept or archived one is restored.

## def outputs

A run's reader outputs held to their models before it lands: every file
under the run's directory that an output row's pattern matches, where the
row takes the run's set, held to that row's model, each problem prefixed
with the file's path in the run, and a file that does not parse named. A
table that breaks its model raises. Only a landing holds a run to it,
since a run landed before a model existed keeps its records as written;
the files no row names, a build's `flags`, `home`, and sources and the
evidence's own records and bytes among them, are kept as written.

## def required

A reader's required inputs are rows of the consumer table, each a named
input and a pattern relative to the run. Every row must match a file of
the restored tree; a hash-only original is never there, and one no reader
requires is no missing input. A reader the table does not name is refused
by name, and a table that breaks its model raises, since no check can
stand on it.
