# The captures' and the pixel identity's `jf`, shims over the workbench's
# bins until JustRetired: a map's poses captured on an image, and
# candidates built with any set.

set shell := ["nu", "-c"]

bin := justfile_directory() / "../../nu/bin"

pose-map map image poses out kernel set="debug":
    nu {{bin}}/nuance/fierce/pose.nu {{map}} {{image}} {{poses}} {{out}} {{kernel}} {{set}}

cand-build dir set:
    nu {{bin}}/nuance.nu build {{dir}} --set {{set}}
