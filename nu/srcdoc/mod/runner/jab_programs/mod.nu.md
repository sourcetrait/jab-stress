# mod.nu

The jab_programs runner's code, reached by its descriptor through the workbench
bin's `runner` verbs, or run whole by `do.nu bench jab_programs <args>`.

## def ready

Before the launch: makes nothing.

## def main

The work: each program's tests through jab's driver in turn, one log of every
run; returns each path's exit and the first error line of each that failed.
