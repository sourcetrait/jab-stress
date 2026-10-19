# eviction.nu

The eviction module's command line, each verb one call of the module, standalone so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/probe/eviction.nu`, its parameters `kernel: path, image: path, disk: path, out: path, mode: string, slots: int = 0, --view: string = "bay", --cycles: int = 2, --modes: int = 0, --tag: string = ""`: the probe in one mode under a slot cap, every settle dumped and read back.
