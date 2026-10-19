# mod.nu

IdentityCorrections (FrameCeiling.md, TwoWorkers' audit): an audited correction
beside each identity of WorkerGauge's batteries, whose build flags were read
from a debug build's `flags` left in the shared scratch images directory, and
whose ELF hash is null, the ELF copies renamed. Every identity under
`<base>/<battery>/<batch>/run_<n>/` is checked first: its flags the debug line
given, its ELF hash null, its image's SHA-256 the file's, and the image's ELF
beside it, `<stem>.elf`, holding no debug-only symbol; then a sidecar binds to
the identity file's SHA-256 and the image's, holds build.flags (the debug line
to the release tree's) and build.elf_sha256 (null to the ELF's), and records the
evidence; then each is read back through `gauge identity corrected`. The
identities stay as written. Its bin:
`nu/bin/nuance/fierce/identity_corrections.nu <base> <release flags file> <nm>
<out.nuon> <battery>...`.

## const DEBUG_ONLY

the symbols only a debug build of fps carries (workers.S)
