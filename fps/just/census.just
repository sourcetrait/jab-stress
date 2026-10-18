# The census's recipes. `build` builds with the symbols named.
# `tilecensus` reads the tile census. `reader-holds` runs the census
# reader's holds over a serial log. `gauge-load` loads the gauge. `check`
# runs nu's IDE check over a file. `hot` and `probe-knobs` run the probes.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
readers := justfile_directory() / "../readers"
probe := justfile_directory() / "../probe"

build dir set:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set {{set}}

tilecensus base out *labels:
    nu {{readers}}/tilecensus.nu {{base}} {{out}} {{labels}}

reader-holds tree serial:
    use {{tree}}/game/fps/test/census_holds.nu [census-reader-holds]; census-reader-holds (open --raw {{serial}} | decode); print "reader-holds: ok"

gauge-load:
    use {{jab}}/game/fps/test/gauge.nu [identity-of]; print "loaded"

check file:
    nu --ide-check 50 {{file}}

hot elf:
    nu {{probe}}/pool/hot.nu {{elf}}

probe-knobs mode out:
    nu {{probe}}/pool/probe_knobs.nu {{mode}} {{out}}
