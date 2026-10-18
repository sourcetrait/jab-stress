# mod.nu

JustToNu's FreshBuildProof: the byte invariant held where no cache can
answer for it. The SDK's build returns before assembling when its stamp
and its record hold, so an image hashed after a build that found its
inputs current proves only that the cache was reused. Every build here
goes into a cache directory made for the run, `XDG_CACHE_HOME` pointed at
it, where the SDK's `target-root` puts the checkout's one target.

## const MATRIX

The tuples the source builds, `nu/nuon/nuance/freshbuild/matrix.nuon`,
its shape `nu/type/nuance/freshbuild/Matrix.nutype`.

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

`nu sdk/nu/jab.nu build`: at the workspace's root it builds the kernel and
every program, at a program path the kernel and that program, and with
`--kernel` at the kernel's directory the kernel alone, each at the tuple.
No `--set` is passed for the empty tuple.

## def disk-of

The SDK builds a program's own disk at a test or a run, never at a build
(`sdk/nu/jab.nu`'s `assets-image`, called by `test-args` and `run-line`),
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
