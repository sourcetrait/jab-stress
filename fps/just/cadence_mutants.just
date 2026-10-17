# The cadence set's program mutants (runners/program_mutants.nuon's
# `jf`): a candidate built debug, its image run through test.nu's cadence
# fixtures alone (`fps/stress/cadence.nu`), which build their own disks;
# the `assets` the runner passes go unread. The control's passing line is
# `cadence: ok`.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
stress := justfile_directory() / "../stress"

cand-build dir:
    nu {{jab}}/sdk/nu/jab.nu build {{dir}} --set debug

image-test image out assets kernel:
    ^nu {{stress}}/cadence.nu {{kernel}} {{image}} {{out}}
