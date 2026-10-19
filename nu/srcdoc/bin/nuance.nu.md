# nuance.nu

The workbench's nuanced CLI, each verb one call of a module under
`nu/mod/`, nothing else in the bin.

## def main freshbuild manifest

`nu nu/bin/nuance.nu freshbuild manifest <jab> <out>`: FreshBuildProof's
manifest of jab's HEAD into a new directory `out`, its fresh cache, the
kernels' flat images, and `manifest.nuon` there. The record lands in
jab-stress-data as a run of `runs/jab/justtonu/`.

## def main freshbuild compare

`nu nu/bin/nuance.nu freshbuild compare <before> <after> <jab>`: a
manifest file taken before the moves held to the out directory of one
taken after, the later's fresh cache read for the remakes, and
`compare.nuon` written there. The pair lands in jab-stress-data as a run
of `runs/jab/justtonu/`.

## def main importmap check

`nu nu/bin/nuance.nu importmap check <jab> <stress> [--landed <groups>]
[--contract <file>] [--out <dir>]`: the import-map checker over both live
trees, the groups landed as one comma-separated string, since a script's
command line carries no list.

## def main runner record stored

`nu nu/bin/nuance.nu runner record stored <run>`: a landed run's
directory held whole by `runner record`, every problem listed, none where
it holds.

## def main runner record restored

`nu nu/bin/nuance.nu runner record restored <dir>`: a restoration's
directory, its receipt and its tree, held to the run it was made from.

## def main runner record required

`nu nu/bin/nuance.nu runner record required <dir> <reader>`: the inputs
the consumer table names for `reader` that the restoration's tree lacks.
