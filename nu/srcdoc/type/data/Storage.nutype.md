# Storage.nutype

The storage metadata of a landed run, `storage.nuon`: a row for each
stored object. Each row gives the object's path in the run, its kind,
`raw`, `container`, or `archive`, its own bytes' length and SHA-256, and
the logical paths it carries: a raw object itself, a container its one
original, an archive its members. Storage is checked against these
objects, never against an original that is no longer there.
