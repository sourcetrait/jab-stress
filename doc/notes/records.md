# Run records

`nu/mod/runner/record/` is the one validator of a run's record in the data
checkout, `../jab-stress-data`. Its models are in `nu/type/data/`: the
manifest at schema 2 (`Run.nutype`) and at schema 1 (`RunSchemaOne.nutype`),
the inventory, the storage, a restoration's receipt, and a log container.

## Running it

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
