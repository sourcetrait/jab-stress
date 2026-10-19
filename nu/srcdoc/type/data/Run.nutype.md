# Run.nutype

The shape of a run's manifest, `run.nuon`, at schema 2, the manifest of
every run landed by the class-aware landing. It names the run's set and
stamp, the task it was made for, how much of its set it took, each part
and where it ran, why it is kept, and the SHA-256 of its inventory and its
storage.

- `scope` takes one of four shapes: the counts alone; with `names`, the
  items a targeted run took; with `combined`, the joint counts of two runs
  that together took their set whole; or with both.
- A part's `source` replaces schema 1's `checkout`: `checkout`, `export`,
  or `synthetic`. A part that ran on an export carries `export`, the
  export's name, its source commit, and the run-relative path of its
  provenance record.
- `inventory` and `storage` are the SHA-256 of `inventory.nuon` and
  `storage.nuon` beside the manifest.

The meaning of each field beyond its type is held by `runner record`.
