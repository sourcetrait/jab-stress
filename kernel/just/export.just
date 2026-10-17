# A kernel candidate's export: a commit's kernel built release with the
# symbols named, comma separated, and frozen with its provenance, gated on
# the ELF's SHA-256 when one is expected.

set shell := ["nu", "-c"]

kexport := justfile_directory() / "../export"

kernel-export repo commit cands symbols="" expected="":
    nu {{kexport}}/export.nu {{repo}} {{commit}} {{cands}} '{{symbols}}' '{{expected}}'
