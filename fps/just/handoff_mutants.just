# The handoff set's program mutants (runners/program_mutants.nuon's
# `jf`): a candidate built with the count, its image tested with the
# handoff fixtures and the count.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"

cand-build dir:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set debug,count

image-test image out assets kernel:
    nu {{jab}}/game/fps/test/test.nu --kernel {{kernel}} --image {{image}} --out {{out}} --set DEBUG,HANDOFF,COUNT --assets {{assets}}
