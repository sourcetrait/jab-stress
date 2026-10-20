# mod.nu

The candidate at its freeze (Qualification.md's freeze): the release tree built
at jab's HEAD, the commits of jab and of the workbench, the game's image, ELF,
and kernel by their SHA-256, the toolchain, and Render Zero's asset tree by its
digest. `main` writes the record to `out`.

## def named-builds

The named builds the qualification's bench files declare at jab's HEAD,
each name and its set, the files agreeing on every name's set.

## def named-build

A named build made in its tree at jab's HEAD as a bench makes it (jab's
`bench build-set`): its set, its tree, its flags, and its image's, ELF's,
and kernel's SHA-256.

## def head-of

A repository's HEAD in full, and whether its tree holds changes.

## def candidate-of

The candidate at its freeze (Qualification.md's freeze): the release
tree built at jab's HEAD (`do.nu build`), then jab's commit, its
checkout's HEAD with no changes, `tag` when given refused unless it
names that HEAD; this repository's commit, its checkout's HEAD,
recorded with whether the checkout holds changes and the commit `tag`
names there, null for none, and never refused; the game's release image,
its ELF, and the kernel built with it, each by its SHA-256, the image's
flags free of DEBUG; the toolchain those flags name, each tool the file
its prefix resolves to with that file's SHA-256 (`gauge identity
resolved-file`); Render Zero's asset tree by gauge/identity's digest, the
tree every run plays; and `builds`, each named build the bench files
declare (named-builds), made before the release tree so the tree ends
holding the candidate's own build, by name (named-build).

- this repository's changes and tag recorded, never refused

## def main

The candidate's record at its freeze (candidate-of), written to `out`.
