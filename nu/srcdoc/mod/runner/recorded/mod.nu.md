# mod.nu

The recorded runner's code, reached by its descriptor through the workbench
bin's `runner` verbs, or run whole by `do.nu bench recorded <args>`: a run of
steps through jab's bins or the workbench's, each step's record what a landed
check needs to stand on its own, the revisions it ran, the symbols its
artifacts carry, those artifacts' bytes and digests, and its output whole. The
run's directory is what `runner land` takes, each step's `step.nuon` its part's
record.

## const JAB

jab, checked out beside the workbench, as every module of it takes jab: the
target root and each build's place come from jab's own `build` and `target`
modules, so a step's artifacts are found where jab's driver put them.

## def ready

Before the launch: the run's directory must not exist, and is made; both
checkouts clean, since a step's record names their commits and a tree holding
changes is no commit; jab's `kernel/` and `sdk/src` equal to `kernel_source`'s
when it names one (`git diff --quiet`); the steps' names distinct, each bin
present, each step's symbols ones the assembler takes, and each fixture a
tracked file of its checkout.

## def main

Each step in turn, every step run and recorded whatever the one before did,
then a failure raised naming every failed step once all are recorded. A step:
its outs' files listed, its bin run from its checkout's root as an executable,
as a user runs `./do`, its words with `{target}` and `{step}` resolved, the
run timed by `timeit`'s monotonic clock; its stdout and stderr saved apart as
`run.stdout` and `run.stderr`; every file it wrote or changed under each out
copied beneath `out_<n>`; the kernel's build and each program's copied beneath
`build/`, the kernel's flat image beside its ELF by the toolchain's `objcopy`,
the loaded bytes; then `step.nuon`: the words, the symbols, the start and end
(realtime, provenance alone), the seconds, the exit, `ok`, both checkouts'
commits and cleanliness, the kernel source asked, the last commit touching
`kernel/` or `sdk/src`, and whether the two trees are equal, each fixture's
last commit, blob, and SHA-256, each artifact with its flags line, the symbols
its `--defsym`s define, and `held`, those symbols the step's exactly, and each
out's copy. `ok` is the exit 0 with every artifact's symbols held.

## def repo-of

A step's checkout by its name, `jab` the sibling checkout and `stress` the
workbench's given checkout.

## def bin-of

A step's bin, its path from its checkout's root.

## def resolved

A word or an out with `{target}` jab's target root and `{step}` the step's own
directory.

## def checkout-of

A checkout's HEAD and whether `git status --porcelain` lists anything.

## def fixture-of

A fixture named `<repo>:<path>`, refused unless git tracks the file.

## def revision-of

A fixture's last commit touching it, its blob at HEAD, and the SHA-256 of its
bytes on disk, which a clean checkout holds equal to the blob.

## def files-of

The regular files under a directory, links and live wires left out, each with
its size and modification time.

## def copied

The files under a directory that a step wrote or changed, by their size and
modification time against the listing taken before it, copied beneath the
step's directory at their relative paths.

## def artifact-of

A kernel's or a program's build for the step's symbols, found where jab's
`build context` places it: its flags, its ELF, and a program's image copied
into the step, each with its SHA-256, the kernel's loaded bytes besides; the
symbols its flags line defines, and `held`, those the step's exactly.
