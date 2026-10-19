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

## def main runner ready

`nu nu/bin/nuance.nu runner ready <harness> <args>`: a harness's checks
before its long launch, its arguments NUON text, its answer NUON, the
values its progress check reads; a refusal on stderr, exit 1.

## def main runner work

`nu nu/bin/nuance.nu runner work <harness> <args>`: a harness's work inside
its long launch, the result NUON on stdout; a failure on stderr, exit 1.

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

## def main hot

`nu nu/bin/nuance.nu hot <elf>`: the renderer's hot routines in a build's
ELF, each with its start, end, and paged and ecall counts, as NUON.

## def main build

`nu nu/bin/nuance.nu build <dir> [--set <symbols>]`: a directory, a
candidate's export or a tree of jab's, built by the sibling checkout's
`nu/bin/do.nu`, the recipes' `cand-build`, `cand-build-debug`,
`cand-build-owner`, `cand-build-release`, and handoff's `build`.

## def main test

`nu nu/bin/nuance.nu test <dir> [--set <symbols>]`: the tests under a
directory run by the sibling checkout's `nu/bin/do.nu`, handoff's
`handoff-set`.

## def main check

`nu nu/bin/nuance.nu check <file> [--ide]`: a nu file checked as a module,
printing `true` or `false`, or with `--ide` by nu's IDE check, the recipes'
`nucheck` and `check`.

## def main fierce tiles keys

`nu nu/bin/nuance.nu fierce tiles keys <api> <out>`: jab's tiles bin's
`keys` over a capture's API stream.

## def main fierce tiles lit-steps

`nu nu/bin/nuance.nu fierce tiles lit-steps <capture> <rect> <crosshair>
<out>`: jab's tiles bin's `lit-steps`, handoff's `litsteps-live`.

## def main fierce tiles handoff

`nu nu/bin/nuance.nu fierce tiles handoff <spec> <index> <out>`: jab's tiles
bin's `handoff`, handoff's `handoff-stats`.

## def main fierce census reader-holds

`nu nu/bin/nuance.nu fierce census reader-holds <tree> <serial>`: the census
reader's holds of a jab tree over a serial log, `reader-holds: ok` once they
hold.

## def main fierce census gauge-load

`nu nu/bin/nuance.nu fierce census gauge-load`: fierce's gauge module loaded
alone, `loaded` printed.
