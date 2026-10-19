# controls.nu

The controls module's command line, each verb one call of the module, standalone so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/sdk/controls.nu`, its parameters `out: path, work: path`: the controls run, one NUON record kept under `out` and printed.

## def main reread

`nu/bin/nuance/sdk/controls.nu reread`, its parameters `record: path`: a controls run's record reread by the current reader, nothing run.
