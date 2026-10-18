# The tile pool's recipes: release candidates, the export, the pool's
# readers and their holds, and the probes.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
readers := justfile_directory() / "../readers"
probe := justfile_directory() / "../probe"

# release with any symbols beside it, comma separated
cand-build-release dir set="":
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set release{{ if set == "" { "" } else { "," + set } }}

export repo commit cands jf expected="" set="":
    nu {{readers}}/export.nu {{repo}} {{commit}} {{cands}} {{jf}} '{{expected}}' --set '{{set}}'

admission base out *labels:
    nu {{readers}}/admission.nu {{base}} {{out}} {{labels}}

poolgauge mode base out *labels:
    nu {{readers}}/poolgauge.nu {{mode}} {{base}} {{out}} {{labels}}

poolgauge-holds script gauge scratch:
    nu {{script}} holds {{gauge}} {{scratch}}

admission-holds script base scratch:
    nu {{script}} holds {{base}} {{scratch}}

probe-knobs mode out:
    nu {{probe}}/pool/probe_knobs.nu {{mode}} {{out}}

hot elf:
    nu {{probe}}/pool/hot.nu {{elf}}
