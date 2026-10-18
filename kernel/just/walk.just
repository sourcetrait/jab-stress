# walk's CADENCE recipes. `cadence` reads a probed run, and `guest` an
# unprobed one. `replay-of` writes a replay stream from a run's own
# records. `cadence-launches` runs walk's own CADENCE_TEST launches
# against a Jab checkout.

set shell := ["nu", "-c"]

walk := justfile_directory() / "../walk"

cadence probe out:
    nu {{walk}}/cadence.nu {{probe}} {{out}}

guest run out:
    nu {{walk}}/cadence.nu guest {{run}} {{out}}

replay-of run stream:
    nu {{walk}}/cadence.nu replay-of {{run}} {{stream}}

cadence-launches jab scratch:
    nu {{walk}}/launches.nu {{jab}} {{scratch}}
