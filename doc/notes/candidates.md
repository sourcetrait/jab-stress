# Kernel candidates

A kernel candidate is a change to the Jab kernel, or to the examples
that run on it, that waits on a measurement or a decision before it is
adopted. While it waits it sits in the source under a build symbol, so a
build without the symbol is the same, byte for byte, as the build before
the change. The candidate is measured against the build without it, both
from one commit.

| Symbol | Task | What it changes |
|---|---|---|
| `flip_batch` | SubmitWait | The kernel's whole-screen flip sends its transfer and its flush as one batch with one wait, as a list of rectangles is sent |
| `prepare` | LoopReorder | bounce, walk, wasd, and pad draw first and wait for the display's tick after, then flip what they kept; it lands only if JointTiming chooses its new presentation rule |

## Testing a candidate

A candidate's cases run in the Jab checkout's own tests, built with its
symbol: `just test test/framecap --set flip_batch` holds the whole flip's
receipts on the candidate, and the same test without the symbol holds
them on the kernel as it is. `just test example/bounce --set prepare`,
and the same for walk, wasd, and pad, runs each example's own test on
its candidate loop.

## Exporting a candidate

A measured kernel is an export, frozen with its provenance. The recipe is
in `kernel/just/export.just` and runs under the real nu:

| Recipe | What it does |
|---|---|
| `just -f kernel/just/export.just kernel-export <jab checkout> <commit> <cands> [symbols] [expected]` | Exports the commit's kernel and builds it release with the symbols, comma separated |
| `just -f kernel/just/export.just walk-export <jab checkout> <commit> <cands> [symbols] [expected]` | Exports the commit's walk and builds it release with the symbols, comma separated, its romfs beside the image |

The export takes the commit's `kernel/src`, its kernel manifest, and
`sdk/src` out of git into `<cands>/kexport_<commit>`, with each symbol
added to the name after a dash, such as `kexport_82992d2-flip_batch`. The
manifest names the Jab checkout as its workspace, so the build uses the
checkout's toolchain and lays the code out as the checkout's own builds
do. `<cands>` must lie in the checkout's target, such as
`<target>/candidates/kernel`, because a kernel there builds beside its
own source, in `kernel/release/`.

Beside the built `jab.elf` the export writes `jab.bin`, the bytes the
kernel loads, and `provenance.nuon`: the commit, the symbols, the build
flags, the checkout's commit and whether it was dirty, the build tool's
SHA-256, the toolchain and the SHA-256 of its assembler, linker, and
objcopy, and the SHA-256 of the ELF and of the loaded bytes. When
`expected` names a SHA-256, the export fails unless its ELF has it. An
export is made once: a second export to the same directory is refused,
and so is a symbol set holding `debug`, since a measured kernel is a
release build.

walk's images, the CADENCE builds that JointTiming's walk arms run, are
exported the same way by the fps readers' `export.nu` with `--program
example/walk`. The export takes the commit's `sdk/src`, walk's `src/` and
manifest, and the `asset/img` directory its manifest names into
`<cands>/export_<commit>-<symbols>`, such as
`export_e21c5ae-cadence-timing`, with `<cands>` in the checkout's target,
such as `<target>/candidates/example/walk`. Beside `walk.jab` sit its
`flags`, `walk.elf`, `walk.romfs`, which genromfs builds from the
export's own copy of the assets as the tool's own run builds it, and
`provenance.nuon`, which carries the romfs's SHA-256 beside the image's
and the ELF's. When `expected` names a SHA-256, the export fails unless
its image has it. walk's wrapper, `example/walk/test/cadence.nu` in the
Jab checkout, runs an export by its image's path and a kernel export's
ELF.
