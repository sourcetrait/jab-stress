# A kernel candidate's export: a commit's kernel built release with the
# symbols named, comma separated, and frozen with its provenance, gated on
# the ELF's SHA-256 when one is expected. walk's images the same way, an
# image's export frozen with its provenance and its romfs beside it, gated
# on the image's SHA-256 when one is expected, through the fps readers'
# export.nu and the pool recipes' release build.

set shell := ["nu", "-c"]

kexport := justfile_directory() / "../export"
readers := justfile_directory() / "../../fps/readers"
pool := justfile_directory() / "../../fps/just/pool.just"

kernel-export repo commit cands symbols="" expected="":
    nu {{kexport}}/export.nu {{repo}} {{commit}} {{cands}} '{{symbols}}' '{{expected}}'

# walk's image at a commit, built release with the symbols named
walk-export repo commit cands symbols="" expected="":
    nu {{readers}}/export.nu {{repo}} {{commit}} {{cands}} {{pool}} '{{expected}}' --set '{{symbols}}' --program example/walk
