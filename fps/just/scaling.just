# GfxScaling's recipes (FrameCeiling): the debug images a parity reads,
# the parity at every count and its faults through workerparity.nu, and
# the batteries' readers.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
readers := justfile_directory() / "../readers"

# a candidate built debug, or debug with OWNER, in its own tree
cand-build-debug dir:
    nu {{jab}}/nu/bin/do.nu build {{dir}} --set debug

cand-build-owner dir:
    nu {{jab}}/nu/bin/do.nu build {{dir}} --set debug,owner

parity kernel image out *flags:
    nu {{readers}}/workerparity.nu {{kernel}} {{image}} {{out}} {{flags}}

fault kernel image out *flags:
    nu {{readers}}/workerparity.nu fault {{kernel}} {{image}} {{out}} {{flags}}

judge out *flags:
    nu {{readers}}/workerparity.nu judge {{out}} {{flags}}

# a battery's gain curves, and a reading's builds as a markdown table
gaincurves mode base out *labels:
    nu {{readers}}/gaincurves.nu {{mode}} {{base}} {{out}} {{labels}}

gaincurves-table reading *builds:
    nu {{readers}}/gaincurves.nu table {{reading}} {{builds}}

# a battery's two band heights as matched pairs (ThreeWorkerGrain)
grainpairs mode base out a b count:
    nu {{readers}}/grainpairs.nu {{mode}} {{base}} {{out}} {{a}} {{b}} {{count}}
