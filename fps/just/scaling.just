# GfxScaling's recipes (FrameCeiling), shims over the workbench's bins
# until JustRetired: the debug images a parity reads, the parity at every
# count and its faults, and the batteries' readers.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
bin := justfile_directory() / "../../nu/bin/nuance/fierce"

# a candidate built debug, or debug with OWNER, in its own tree
cand-build-debug dir:
    nu {{jab}}/nu/bin/do.nu build {{dir}} --set debug

cand-build-owner dir:
    nu {{jab}}/nu/bin/do.nu build {{dir}} --set debug,owner

parity kernel image out *flags:
    nu {{bin}}/workerparity.nu {{kernel}} {{image}} {{out}} {{flags}}

fault kernel image out *flags:
    nu {{bin}}/workerparity.nu fault {{kernel}} {{image}} {{out}} {{flags}}

judge out *flags:
    nu {{bin}}/workerparity.nu judge {{out}} {{flags}}

# a battery's gain curves, and a reading's builds as a markdown table
gaincurves mode base out *labels:
    nu {{bin}}/gaincurves.nu {{mode}} {{base}} {{out}} {{labels}}

gaincurves-table reading *builds:
    nu {{bin}}/gaincurves.nu table {{reading}} {{builds}}

# a battery's two band heights as matched pairs (ThreeWorkerGrain)
grainpairs mode base out a b count:
    nu {{bin}}/grainpairs.nu {{mode}} {{base}} {{out}} {{a}} {{b}} {{count}}
