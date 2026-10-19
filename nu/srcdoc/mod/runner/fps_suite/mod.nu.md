# mod.nu

The fps_suite runner's code, reached by its descriptor through the workbench
bin's `runner` verbs, or run whole by `do.nu bench fps_suite <args>`.

## def ready

Before the launch: makes the log's directory.

## def main

The work: the program's tests through jab's `nu/bin/do.nu test`, from jab's
root, the log saved; a run without `fps: ok` an error; returns ok, the exit, and
the gauge's lines.
