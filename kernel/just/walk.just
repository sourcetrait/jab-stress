# walk's CADENCE recipes: the reader over a probed run or an unprobed
# one, a replay stream from a run's own records, the reader's own
# fixtures, the script given so a mutant's copy runs in its place, and
# walk's own CADENCE_TEST launches against a Jab checkout.

set shell := ["nu", "-c"]

walk := justfile_directory() / "../walk"

cadence probe out:
    nu {{walk}}/cadence.nu {{probe}} {{out}}

guest run out:
    nu {{walk}}/cadence.nu guest {{run}} {{out}}

replay-of run stream:
    nu {{walk}}/cadence.nu replay-of {{run}} {{stream}}

cadence-holds script scratch:
    nu {{script}} holds {{scratch}}

cadence-launches jab scratch:
    nu {{walk}}/launches.nu {{jab}} {{scratch}}

cadence-mutants jab set scratch:
    nu {{walk}}/mutants.nu {{jab}} {{set}} {{scratch}}
