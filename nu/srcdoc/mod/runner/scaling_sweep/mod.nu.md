# mod.nu

The scaling_sweep runner's code, reached by its descriptor through the workbench
bin's `runner` verbs, or run whole by `do.nu bench scaling_sweep <args>`.

## def ready

Before the launch: refuses a `base` that exists or a missing image, then makes
`base`; returns the batch count.

## def main

The work: workers 3 to 7 at grains 0, 16, 32, and 64 on eight harts, then
reversed, three runs each on the route; each field compared, diagnostic; returns
the batches done and the compares.
