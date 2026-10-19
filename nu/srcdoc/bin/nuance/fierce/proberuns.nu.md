# proberuns.nu

The proberuns module's command line, each verb one call of the module,
standalone so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/proberuns.nu`, its parameters `base: string, out:
string, ...labels: string, --eps: int`: ProbeRuns' reading of the probed
batches under `base`, saved.

## def main observer

`nu/bin/nuance/fierce/proberuns.nu observer`, its parameters `base: string,
out: string, --probed: string, --plain: string`: the observer sets' reading
under `base`, probed against plain, saved.
