# TileLayout's LayoutProbe, shims over the workbench's bins until
# JustRetired: the layout candidates from the checkout's `src` at a
# commit, built with any set, and a build's hot routines.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
bin := justfile_directory() / "../../nu/bin"

layout-cands cands commit *names:
    nu {{bin}}/nuance/fierce/probe/layout.nu {{cands}} {{commit}} {{names}}

cand-build dir set:
    nu {{jab}}/nu/bin/do.nu build {{dir}} --set {{set}}

hot elf:
    nu {{bin}}/nuance.nu hot {{elf}}
