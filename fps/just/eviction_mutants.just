# The eviction set's program mutants (runners/program_mutants.nuon's
# `jf`): a candidate built debug, its image run through the release
# tier's eviction fixtures, all or those named, on the still disk the
# runner passes as `assets`.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
stress := justfile_directory() / "../stress"

cand-build dir:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set debug

image-test image out assets kernel *fixtures:
    ^nu {{stress}}/eviction.nu {{kernel}} {{image}} {{assets}} {{out}} {{fixtures}}
