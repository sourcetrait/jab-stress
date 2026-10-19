# mod.nu

The captures_compare runner's code, reached by its descriptor through the
workbench bin's `runner` verbs, or run whole by `do.nu bench captures_compare
<args>`.

## def ready

Before the launch: refuses a set's directory under `root` that exists.

## def main

The work: the same captures saved as `new1_captures.nuon`, each held to the
base's `base_<kind>` row of its map and pose; returns the count, the exits, how
many are the same, and the poses that differ.
