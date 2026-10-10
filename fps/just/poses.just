# The captures' and the pixel identity's `jf`: a map's poses captured on
# an image, and candidates built with any set.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"

pose-map map image poses out kernel set="debug":
    nu {{jab}}/game/fps/test/pose.nu {{map}} {{poses}} {{out}} --kernel {{kernel}} --image {{image}} --set {{set}}

cand-build dir set:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set {{set}}
