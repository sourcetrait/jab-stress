# The smoke runner's `jf` (runners/smoke.nuon): the development smoke at
# the jab root. Reconstructed: the original recipe's file is gone, and
# the argument order here is the runner's, unverified against `just do`.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"

smoke seeds seconds:
    cd {{jab}}; ^just do smoke {{seeds}} {{seconds}}
