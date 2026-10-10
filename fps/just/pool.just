# The tile pool's recipes and the program mutants' `jf` for the pool and
# packet sets: debug and release candidates, the export, the pool's
# readers and their holds, the gauge's rules over a mirror, and the
# probes. The mirror lives outside the session's scratch, where the gauge
# mutants' runner writes it.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
readers := justfile_directory() / "../readers"
probe := justfile_directory() / "../probe"

cand-build dir:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set debug

cand-build-release dir:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set release

image-test image out assets kernel:
    nu {{jab}}/game/fps/test/test.nu --kernel {{kernel}} --image {{image}} --out {{out}} --set DEBUG --assets {{assets}}

export repo commit cands jf expected="":
    nu {{readers}}/export.nu {{repo}} {{commit}} {{cands}} {{jf}} '{{expected}}'

admission base out *labels:
    nu {{readers}}/admission.nu {{base}} {{out}} {{labels}}

poolgauge mode base out *labels:
    nu {{readers}}/poolgauge.nu {{mode}} {{base}} {{out}} {{labels}}

poolgauge-holds script gauge scratch:
    nu {{script}} holds {{gauge}} {{scratch}}

admission-holds script base scratch:
    nu {{script}} holds {{base}} {{scratch}}

# the gauge's rules over the mirror the gauge mutants' runner writes
rules-mirror out mirror=(env("XDGX_TMP_HOME") / "jab-stress" / "mirror"):
    use {{mirror}}/game/fps/test/test.nu [gauge-rules]; gauge-rules {{out}}; print "rules: ok"

probe-knobs mode out:
    nu {{probe}}/pool/probe_knobs.nu {{mode}} {{out}}

hot elf:
    nu {{probe}}/pool/hot.nu {{elf}}
