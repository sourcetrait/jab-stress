# A kernel candidate's export, a shim over the workbench's bins until
# JustRetired: a commit's kernel built release with the symbols named,
# comma separated, and frozen with its provenance, gated on the ELF's
# SHA-256 when one is expected. walk's images the same way, an image's
# export frozen with its provenance and its romfs beside it, gated on the
# image's SHA-256 when one is expected, through the fierce freeze bin, the
# build the checkout's root `do`.

set shell := ["nu", "-c"]

bin := justfile_directory() / "../../nu/bin/nuance"

kernel-export repo commit cands symbols="" expected="":
    nu {{bin}}/kernel/freeze.nu {{repo}} {{commit}} {{cands}} '{{symbols}}' '{{expected}}'

# walk's image at a commit, built release with the symbols named
walk-export repo commit cands symbols="" expected="":
    nu {{bin}}/fierce/freeze.nu {{repo}} {{commit}} {{cands}} '{{expected}}' --set '{{symbols}}' --program example/walk
