# mod.nu

JustToNu's FreshBuildProof: the byte invariant held where no cache can
answer for it. The SDK's build returns before assembling when its stamp
and its record hold, so an image hashed after a build that found its
inputs current proves only that the cache was reused. Every build here
goes into a cache directory made for the run, `XDG_CACHE_HOME` pointed at
it, where the SDK's `target root` puts the checkout's one target.

## const MATRIX

The tuples the source builds, `nu/nuon/nuance/freshbuild/matrix.nuon`,
its shape `nu/type/nuance/freshbuild/Matrix.nutype`.

## const MOVES

The moves a comparison reads an earlier manifest through,
`nu/nuon/nuance/freshbuild/moves.nuon`, its shape
`nu/type/nuance/freshbuild/Moves.nutype`.

## def tuple-of

The SDK's own rule for a build's symbols (`--set`): each name screaming
snake case, sorted, and deduplicated, so a row's key is the build's.

## def tree-of

DEBUG picks the target's `debug/` tree, every other build its `release/`.

## def target-in

A fresh cache holds one checkout's target, `jab/target/<checkout>-<hash>`,
beside the SDK's retire home, `jab/target/tmp`, which the build makes too;
any other count means the cache was not fresh.

## def programs-of

Every `program.jab.toml` of the checkout outside `.git`, `.target`, and
`target`, the 48 programs the suite tests.

## def build-at

`nu nu/bin/do.nu build`, the checkout's own bin: at the workspace's root it
builds the kernel and every program, at a program path the kernel and that program, and with
`--kernel` at the kernel's directory the kernel alone, each at the tuple.
No `--set` is passed for the empty tuple.

## def disk-of

The SDK builds a program's own disk at a test or a run, never at a build
(the disk module's `assets-image`, called by `test-args` and `run-line`),
so this builds it the same way: `genromfs -d <dir> -f <out>/<name>.romfs
-V <name>`, the directory the manifest's `assets`, relative to it, or its
`target_assets`, a tree under the target's asset shard,
`<target>/asset/<program>/`, that the program's preparation compiles. A
name past the 127 bytes the SDK's volume name keeps is refused, since the
SDK would cut it. Five programs have a disk: walk, techno, logo,
blocklist, and the game.

## def program-rows

A build replaces the image a tree held, so each tuple's rows are read the
moment its build ends, before the next build writes over them. The disk
is built and hashed with them.

## def kernel-rows

The loaded bytes are the ELF's flat image, `objcopy -O binary`, the
toolchain's prefix the last word of the kernel's `flags`, the bytes a
kernel export calls its loaded bytes. Both rows name the ELF as their
path.

## def manifest

The checkout must hold no changes, since the manifest is of its commit.
Each tuple of each matrix row is built in turn, the workspace's two first;
the kernel at a tuple is hashed again with every program built at it, and
two digests of one kernel stop the run as a build that is not
reproducible, and so do two digests of one program's disk in one tree,
its inputs the same at every tuple. A row taken twice stops it too.
`manifest.nuon` records the commit, every build, and every row.

## def key-of

A row's exact build and role: the program, the tree, the sorted symbols,
and the role, the key a manifest takes each row by.

## def moved-program

A path under a moved one takes the move's new prefix; a path the moves
do not reach stays.

## def moved-row

The kernel's rows stay as written. A program's row takes its program's
new place, and a renamed program's file, its stem the old name, the new
name's.

## def remade-elves

`git worktree add --detach` of the later commit under the comparison's
scratch, the checkout's `extern/riscv` link made there so the build takes
the same toolchain, each renamed program's manifest given its old name
back, then each tuple built into a fresh cache and its `<old>.elf` hashed.
The worktree is removed with `--force` whatever the builds did, and an
error of theirs is raised after.

## def remade-disk

The disk's tree copied, every NUON record of it naming the program's
absolute directory rewritten to name the old one, the `tile.nuon` of a
tree compiled before jab c804ccb the one that does, and genromfs run over
the copy under the
old name. A copied tree makes the same image as the original, since
genromfs reads it in the same order.

## def compare

Each earlier row, read through the moves, found in the later manifest by
its key: absent, at another path, or of other bytes is refused, but for a
renamed program's ELF and disk, which are remade under the old name and
place and must hash to the earlier row. A later row with no earlier one is
refused too. A disk is remade once a tree and its proof shared by the
tuples built at it.
