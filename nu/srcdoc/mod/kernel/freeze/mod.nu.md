# mod.nu

A kernel candidate's export (SubmitWait, and JointTiming's P0 and P2): a
measured kernel frozen with its provenance. `git archive` of a commit's
`kernel/src`, `kernel/kernel.jab.toml`, and `sdk/src` into
`<cands>/kexport_<commit>[-<symbol>...]`; the manifest's `workspace` the
checkout's, so the toolchain is the checkout's `extern/riscv` and the code's
layout the suite's, and its `do`, a script the export does not carry, dropped;
`source.nuon` naming the commit and the symbols; built release with the symbols
by the checkout's build verb, the export lying in the checkout's target, so the
build lands beside it in `kernel/release/`; then beside the ELF, `jab.bin`,
objcopy's flat image, the bytes the kernel loads, and `provenance.nuon`: the
commit, the symbols, the flags, the build tool's identity (`identity reader`
over the checkout: its commit and state, its interpreters), the toolchain's
prefix, its version, and the SHA-256 of its assembler, linker, and objcopy, the
ELF's SHA-256 and the loaded bytes'. A gate before anything measures it: the
ELF's SHA-256 the one `expected` names, unless `expected` is "". DEBUG is
refused, since a measured kernel is a release one. Its bin:
`nu/bin/nuance/kernel/freeze.nu <repo> <commit> <cands> <symbols> <expected>`,
the symbols comma separated, "" for none.
