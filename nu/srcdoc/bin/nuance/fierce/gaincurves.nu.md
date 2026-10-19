# gaincurves.nu

The gaincurves module's command line, each verb one call of the module,
standalone so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/gaincurves.nu`, its parameters `mode: string, base:
string, out: string, ...labels: string`: A battery's gain curves saved to `out`
and summarised.

## def main table

`nu/bin/nuance/fierce/gaincurves.nu table`, its parameters `reading: string,
...builds: string`: A saved reading's builds printed as a markdown table.
