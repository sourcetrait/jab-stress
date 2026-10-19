# The census's recipes, shims over the workbench's bins until JustRetired.
# `build` builds with the symbols named. `tilecensus` reads the tile census.
# `reader-holds` runs the census reader's holds over a serial log.
# `gauge-load` loads the gauge. `check` runs nu's IDE check over a file.
# `hot` and `probe-knobs` run the probes.

set shell := ["nu", "-c"]

bin := justfile_directory() / "../../nu/bin"

build dir set:
    nu {{bin}}/nuance.nu build {{dir}} --set {{set}}

tilecensus base out *labels:
    nu {{bin}}/nuance/fierce/tilecensus.nu {{base}} {{out}} {{labels}}

reader-holds tree serial:
    nu {{bin}}/nuance.nu fierce census reader-holds {{tree}} {{serial}}

gauge-load:
    nu {{bin}}/nuance.nu fierce census gauge-load

check file:
    nu {{bin}}/nuance.nu check {{file}} --ide

hot elf:
    nu {{bin}}/nuance.nu hot {{elf}}

probe-knobs mode out:
    nu {{bin}}/nuance/fierce/probe/knobs.nu {{mode}} {{out}}
