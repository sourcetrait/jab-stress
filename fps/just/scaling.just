# GfxScaling's recipes (FrameCeiling): the debug images a parity reads,
# the parity at every count and its faults through workerparity.nu.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
readers := justfile_directory() / "../readers"

# a candidate built debug, or debug with OWNER, in its own tree
cand-build-debug dir:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set debug

cand-build-owner dir:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set debug,owner

parity kernel image out *flags:
    nu {{readers}}/workerparity.nu {{kernel}} {{image}} {{out}} {{flags}}

fault kernel image out *flags:
    nu {{readers}}/workerparity.nu fault {{kernel}} {{image}} {{out}} {{flags}}

judge out *flags:
    nu {{readers}}/workerparity.nu judge {{out}} {{flags}}
