# mod.nu

The cadence_image_battery runner's code, reached by its descriptor through the
workbench bin's `runner` verbs, or run whole by `do.nu bench
cadence_image_battery <args>`.

## def ready

Before the launch: refuses a `base` that exists or a named image missing, then
makes `base`.

## def main

The work: each batch at cadence 0, three runs, on its image or the fresh build,
then each field compared; returns the batches done and the compares' exits.
