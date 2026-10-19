# walk's CADENCE recipes, shims over the walk bins until JustRetired.
# `cadence` reads a probed run, and `guest` an unprobed one. `replay-of`
# writes a replay stream from a run's own records. `cadence-launches`
# runs walk's own CADENCE_TEST launches against a Jab checkout.

set shell := ["nu", "-c"]

walk := justfile_directory() / "../../nu/bin/nuance/kernel/walk"

cadence probe out:
    nu {{walk}}.nu {{probe}} {{out}}

guest run out:
    nu {{walk}}.nu guest {{run}} {{out}}

replay-of run stream:
    nu {{walk}}.nu replay-of {{run}} {{stream}}

cadence-launches jab scratch:
    nu {{walk}}/launches.nu {{jab}} {{scratch}}
