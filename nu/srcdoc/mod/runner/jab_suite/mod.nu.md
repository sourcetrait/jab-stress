# mod.nu

The jab_suite runner's code, reached by its descriptor through the workbench
bin's `runner` verbs, or run whole by `do.nu bench jab_suite <args>`.

## def ready

Before the launch: makes the log's directory, so the suite's output is saved
when it ends.

## def main

The work: jab's whole suite through its driver, the log saved; returns the exit,
the pass table's rows, its failed rows, and the log's last 1500 characters.
