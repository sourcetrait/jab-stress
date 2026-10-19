# mod.nu

The jab_do runner's code, reached by its descriptor through the workbench bin's
`runner` verbs, or run whole by `do.nu bench jab_do <args>`.

## def ready

Before the launch: makes the log's directory.

## def main

The work: the root's `nu/bin/<bin>.nu <verb> <words>` from jab's root under the
environment given, its whole output saved; a non-zero exit an error; returns the
exit and the last lines. A bench and its watch are two launches, the watch
first: `nuance` `watch` `[bench <program>/<bench>]`, then `do` `bench`
`[<program>/<bench>]`.
