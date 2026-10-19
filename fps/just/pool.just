# The tile pool's recipes, shims over the workbench's bins until
# JustRetired. `cand-build-release` builds a release candidate. `export`
# freezes a measured image with its provenance; its `jf` is kept for its
# callers and read by nothing, the build being the checkout's root `do`.
# `admission` and `poolgauge` run the pool's readers. `probe-knobs` and
# `hot` run the probes.

set shell := ["nu", "-c"]

bin := justfile_directory() / "../../nu/bin"

# release with any symbols beside it, comma separated
cand-build-release dir set="":
    nu {{bin}}/nuance.nu build {{dir}} --set release{{ if set == "" { "" } else { "," + set } }}

export repo commit cands jf expected="" set="":
    nu {{bin}}/nuance/fierce/freeze.nu {{repo}} {{commit}} {{cands}} '{{expected}}' --set '{{set}}'

admission base out *labels:
    nu {{bin}}/nuance/fierce/admission.nu {{base}} {{out}} {{labels}}

poolgauge mode base out *labels:
    nu {{bin}}/nuance/fierce/poolgauge.nu {{mode}} {{base}} {{out}} {{labels}}

probe-knobs mode out:
    nu {{bin}}/nuance/fierce/probe/knobs.nu {{mode}} {{out}}

hot elf:
    nu {{bin}}/nuance.nu hot {{elf}}
