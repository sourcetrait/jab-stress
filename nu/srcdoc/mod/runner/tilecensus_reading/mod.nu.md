# mod.nu

The tilecensus_reading runner's code, reached by its descriptor through the
workbench bin's `runner` verbs, or run whole by `do.nu bench tilecensus_reading
<args>`.

## def ready

Before the launch: refuses a `census.nuon` under `base` that exists.

## def main

The work: the tile census read over the batches into `census.nuon`, its output
`census_reread.log`; a failure an error; returns the exit and the problems
counted.
