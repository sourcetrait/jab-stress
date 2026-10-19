# mod.nu

The worker_battery runner's code, reached by its descriptor through the
workbench bin's `runner` verbs, or run whole by `do.nu bench worker_battery
<args>`.

## def ready

Before the launch: refuses a `base` that exists or a named image missing, then
makes `base`.

## def main

The work: each batch at its workers and grain, with the CPU when `cpu`, then
each field compared; returns the batches done and the compares.
