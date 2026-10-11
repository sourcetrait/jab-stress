# TileLayout's LayoutProbe: the layout candidates from the checkout's
# `src` at a commit, built with any set, and a build's hot routines.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
probe := justfile_directory() / "../probe"

layout-cands cands commit *names:
    nu {{probe}}/layout/candidates.nu {{cands}} {{commit}} {{names}}

cand-build dir set:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set {{set}}

hot elf:
    nu {{probe}}/pool/hot.nu {{elf}}
