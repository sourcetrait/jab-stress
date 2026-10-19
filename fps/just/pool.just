# The tile pool's recipes. `cand-build-release` builds a release
# candidate. `export` freezes a measured image with its provenance.
# `admission` and `poolgauge` run the pool's readers. `probe-knobs` and
# `hot` run the probes.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
readers := justfile_directory() / "../readers"
probe := justfile_directory() / "../probe"

# release with any symbols beside it, comma separated
cand-build-release dir set="":
    nu {{jab}}/nu/bin/do.nu build {{dir}} --set release{{ if set == "" { "" } else { "," + set } }}

export repo commit cands jf expected="" set="":
    nu {{readers}}/export.nu {{repo}} {{commit}} {{cands}} {{jf}} '{{expected}}' --set '{{set}}'

admission base out *labels:
    nu {{readers}}/admission.nu {{base}} {{out}} {{labels}}

poolgauge mode base out *labels:
    nu {{readers}}/poolgauge.nu {{mode}} {{base}} {{out}} {{labels}}

probe-knobs mode out:
    nu {{probe}}/pool/probe_knobs.nu {{mode}} {{out}}

hot elf:
    nu {{probe}}/pool/hot.nu {{elf}}
