# launches.nu

The launches module's command line, each verb one call of the module, standalone so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/kernel/walk/launches.nu`, its parameters `jab_dir: path, scratch: path, --only: string = ""`: walk's own CADENCE_TEST launches against a Jab checkout.
