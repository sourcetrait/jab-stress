# The census's recipes and the census set's `jf`: candidates with the
# census built in, the census image tested, the tile census's reading and
# its holds, and the census reader's holds on a mirror tree.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
ops := env("HOME") / "ai/two/iter/jab/subiter/fps/operational"
probe := justfile_directory() / "../probe"

cand-build dir:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set debug,census

build dir set:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set {{set}}

image-test image out assets kernel:
    nu {{jab}}/game/fps/test/test.nu --kernel {{kernel}} --image {{image}} --out {{out}} --set CENSUS,DEBUG --assets {{assets}}

tilecensus base out *labels:
    nu {{ops}}/tilecensus.nu {{base}} {{out}} {{labels}}

tilecensus-holds script base scratch:
    nu {{script}} holds {{base}} {{scratch}}

reader-holds tree serial:
    use {{tree}}/game/fps/test/census_holds.nu [census-reader-holds]; census-reader-holds (open --raw {{serial}} | decode); print "reader-holds: ok"

gauge-rules tree out:
    use {{tree}}/game/fps/test/test.nu [gauge-rules]; gauge-rules {{out}}; print "gauge-rules: ok"

gauge-load:
    use {{jab}}/game/fps/test/gauge.nu [identity-of]; print "loaded"

check file:
    nu --ide-check 50 {{file}}

hot elf:
    nu {{probe}}/pool/hot.nu {{elf}}

probe-knobs mode out:
    nu {{probe}}/pool/probe_knobs.nu {{mode}} {{out}}
