# mod.nu

The smoke runner's code, reached by its descriptor through the workbench bin's
`runner` verbs, or run whole by `do.nu bench smoke <args>`.

## def ready

Before the launch: makes the log's directory, so the smoke's output is saved
when it ends.

## def main

The work: fierce's development smoke by its bin, the log saved; a non-zero exit
an error naming its telling lines; returns the exit and those lines.
