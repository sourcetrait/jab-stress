# mod.nu

The grain_battery runner's code, reached by its descriptor through the workbench
bin's `runner` verbs, or run whole by `do.nu bench grain_battery <args>`.

## def ready

Before the launch: refuses any battery's base that exists or a missing image;
returns the four batteries' names, bases, and batch counts, which the check
reads.

## def main

The work: ThreeWorkerGrain: forced W 3 at 16 and 32 rows in the order 16 32 32
16 16 32 32 16, three runs each, on four and eight harts over the settled and
the factory routes, each battery's critical and raster compared, diagnostic;
returns each battery's batches and compares.
