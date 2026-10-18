# Fresh builds

`nu/mod/nuance/freshbuild/` builds every tuple of build symbols that
Jab's source builds, into a target no earlier build has touched, and
records the SHA-256 of every artifact. A later build of the same tuples
is held to that record, so a change that should leave every image as it
was shows that it did.

Jab's tool skips a build whose outputs are newer than its inputs, so an
image hashed after an ordinary build proves only that the cache was used.
Here every build goes into a fresh cache: the run sets `XDG_CACHE_HOME` to
a directory it makes, and Jab's tool puts the checkout's target under it.

## Running it

```
nu nu/bin/nuance.nu freshbuild manifest <jab checkout> <out>
```

`out` must not exist. The Jab checkout must hold no changes, since the
record is of its commit. The run writes:

- `<out>/cache/`, the fresh target, every build's outputs;
- `<out>/loaded/`, each kernel's flat image, the bytes it loads;
- `<out>/manifest.nuon`, the record: the commit, every build with its
  exit, and every row.

It takes a few minutes here. The record goes to the data checkout as a
run of `runs/jab/justtonu/`; the cache is bulk and stays outside both
repositories, under `$XDGX_TMP_HOME/jab-stress/freshbuild/`.

## The tuples

`nu/nuon/nuance/freshbuild/matrix.nuon` lists them: the whole workspace
in release and under `DEBUG`, then each program built with other symbols,
such as the game's `COUNT` and `CENSUS` builds, walk's `CADENCE` builds,
and the kernel alone with `FLIP_BATCH`. Each tuple is built in turn, and
its outputs are hashed the moment its build ends, since the next build of
the same tree replaces them.

## The rows

A row is keyed by its exact build: the program, the tree (`release` or
`debug`, by `DEBUG`), and the sorted symbols. Each row is one role:

- `program_jab`, the program's image;
- `program_elf`, its ELF;
- `romfs_disk`, its own disk, for a program with assets, built with
  `genromfs` as a run builds it, since a build makes none;
- `kernel_elf`, the kernel's ELF;
- `kernel_loaded`, the bytes the kernel loads, `objcopy -O binary`'s
  image of its ELF.

Each row carries its path inside the tree, its SHA-256, and its size. The
kernel is built again with every program, so a kernel at one tuple is
hashed several times, and a program's disk is built at each of its
tuples; two different digests of either stop the run, since the build
would not be reproducible.
