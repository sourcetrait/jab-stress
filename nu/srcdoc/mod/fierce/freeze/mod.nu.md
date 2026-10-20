# mod.nu

ImageProvenance (FrameCeiling.md, TwoWorkers' audit): a measured image frozen
with its provenance. `git archive` of a commit's `sdk/src`, the program's `src/`
and manifest, and the directory its manifest's `assets` names, the program
`--program`'s (the game unless given, at the commit's own place for it,
`game/fps/1k` before FpsRootLayout, `game/fps` after, and `kit/fierce` from
KitFierce; walk's CADENCE images `example/walk`), into
`<cands>/export_<commit>`, each symbol of `--set` added to the name after a dash
(`export_<commit>-footprint`), the manifest's `sdk`, `includes`, and `link`
redirected into the export, since the builder reads `link` itself, its `assets`
to the export's copy, and its `workspace` the checkout's, whose kernel and
target the runs use; its declaration, `specs`, `[reserved]`, and `[feature]`,
and the run's shape, `display` and `paired`, kept, so the image reserves what
the program declares, and `prepare`, `do`, and `target_assets`, which name the
program's own tree, dropped; `source.nuon` naming the commit and the symbols;
built release there by the checkout's root `do`, its set `release` and the
symbols beside it; a program with assets given its romfs beside the image,
`<name>.romfs`, genromfs over the export's copy with the program's name as the
volume, as the tool's run makes it; then beside the image, which the build
writes with its `home`, `flags`, and `<name>.elf`, `provenance.nuon`
(provenance-of). A gate before anything measures it: the image's SHA-256 the one
`expected` names, unless `expected` is "". DEBUG and RELEASE are refused among
the symbols, a measured image being a release build and `release` the build's
own. `--debug` exports the debug build instead, the qualification's audio
runs' (RegressionSuite): its set `debug` and the symbols, DEBUG required of
its flags and named among its provenance's symbols, `-debug` after the
commit in its name. Its bin: `nu/bin/nuance/fierce/freeze.nu <repo> <commit>
<cands> <expected> [--set <symbols>] [--program <path>] [--debug]`, the
symbols comma separated.

## const TIMING

The timing domain a launch under the supervisor measures in, as a freeze
records it: the go's `Instant` the origin of every receipt time, in
nanoseconds, QEMU's CPU read by the supervisor, a result's times in seconds
from the go and its `wall_seconds` from the go to the reap, the caller's
realtime clock giving dates alone; a run captured before the freeze keeps
the timing it was captured under.

## def launcher-of

The launcher a freeze's measurements run under (FrameCeiling's fix pass,
RelaySupervision): the supervisor's binary as jab's `supervise binary`
builds it from the SDK's own checkout, its path and SHA-256; the checkout's
commit and state (`identity reader`); the supervisor's bounds (`supervise
bounds`); and the timing domain. Its bin's `launcher <repo> <out>` writes
it once.

## def symbols-of

The build symbols a set names as the tool makes them: screaming snake
case, each once, sorted.

## def provenance-of

An image's provenance, written beside it as `provenance.nuon` and
returned: the commit for the source and the SDK, the symbols the build
names beside its tree's, the build tool's identity apart (`identity
reader` over the checkout, its commit and state and its interpreters), the
toolchain's prefix, its advertised version, and the SHA-256 of the
resolved assembler, linker, and objcopy, the flags, and the image's and
the ELF's SHA-256, the ELF the image's stem's; and the romfs's, the
stem's too, when one sits beside the image.

## def game-place

The game's place at a commit: kit/fierce from KitFierce, game/fps/1k
before FpsRootLayout, game/fps between.
