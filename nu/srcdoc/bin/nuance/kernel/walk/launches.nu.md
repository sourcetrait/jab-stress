# launches.nu

The launches module's command line, each verb one call of the module, standalone
so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/kernel/walk/launches.nu`, its parameters `jab_dir: path, scratch:
path, --only: string = ""`: walk's own CADENCE_TEST launches against a Jab
checkout.

## def main reread

`nu/bin/nuance/kernel/walk/launches.nu reread`, its parameters `tree: path, out:
path`: A landed run's recorded cases read again by today's reader, each held as
its launch held it.
