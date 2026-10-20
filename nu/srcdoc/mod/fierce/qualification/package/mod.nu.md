# mod.nu

The candidate's host package for a target (HostPackage): the guest bytes a
host's bench runs, from the candidate's export, each held to the SHA-256 the
candidate's record names, with the inputs the gauge reads and the bench as its
package runs it, made into one tar by the SDK's package module. A host extracts
it and runs `./do bench kit/fierce/qual_<target> --package <its directory>` from
its own checkout; its QEMU, launcher, shim, and backends stay its own.

## def program-of

The export's program directory, the one holding its manifest.

## def held

## def named-artifacts

A named build's artifacts from its own export (freeze.nu with its set, or
`--debug` for the debug build), the export of the candidate's commit: its
image held to the candidate's build of that name, its ELF to its export's
provenance, which must name the candidate's commit and that image, its
flags, demand, provenance, and source record, and the kernel its tree's
builds run, held to the candidate's build's, laid at `build/<name>`, where
a packaged bench's `{build:<name>}` reads them; and its identity for the
manifest.

## def main

The package: the export of the candidate's commit (freeze.nu), its
`source.nuon` naming that commit whole; the release image, its ELF, its
flags, its demand record, its provenance, and its source record laid
together, with no `home`, so a reader resolves the program's source from
the package; the image's bytes held to the candidate's, and the ELF to its
export's provenance, which must name the candidate's commit and image,
since the export's ELF carries RELEASE in its symbol table where the
candidate's tree build's does not, the manifest naming the freeze's ELF
beside the tree build's; the kernel the export's build ran with, its ELF and its
loaded flat image's SHA-256 both named, each for the check that uses it;
the asset tree, the checkout's shard's, held to the candidate's digest;
the factory route at the candidate's commit; and the bench, the
candidate's bench file at its commit as packaged-bench writes it; and each
named build of the candidate's from its export, `--exports` a NUON record
of name to export directory, every build given one and none foreign
(named-artifacts), the manifest's identities naming each. The inputs
written once beside the stage, the stage a fresh directory beside `out`
unless `--stage` names one, nothing deleted.
