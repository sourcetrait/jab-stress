# mod.nu

The pixel_identity runner's code, reached by its descriptor through the
workbench bin's `runner` verbs, or run whole by `do.nu bench pixel_identity
<args>`.

## def ready

Before the launch: refuses `<root>/captures` where it exists, then makes it.

## def main

The work: every map's poses captured on each set, maps outermost, saved as
`captures.nuon`, each other set's held to the base set's; returns the counts and
the poses that differ.
