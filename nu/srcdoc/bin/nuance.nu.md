# nuance.nu

The workbench's nuanced CLI, each verb one call of a module under
`nu/mod/nuance/`, nothing else in the bin.

## def main freshbuild manifest

`nu nu/bin/nuance.nu freshbuild manifest <jab> <out>`: FreshBuildProof's
manifest of jab's HEAD into a new directory `out`, its fresh cache, the
kernels' flat images, and `manifest.nuon` there. The record lands in
jab-stress-data as a run of `runs/jab/justtonu/`.
