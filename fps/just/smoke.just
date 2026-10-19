# The smoke runner's `jf` (runners/smoke.nuon), a shim until JustRetired:
# the development smoke, fierce's own `nuance.nu smoke <seeds> <seconds>`
# in the checkout beside this one.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"

smoke seeds seconds:
    nu {{jab}}/kit/fierce/nu/bin/nuance.nu smoke {{seeds}} {{seconds}}
