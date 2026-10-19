# eviction.nu

The eviction module's command line, each verb one call of the module, standalone
so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/probe/eviction.nu`, its parameters `kernel: path, image:
path, disk: path, out: path, mode: string, slots: int = 0, --view: string =
"bay", --cycles: int = 2, --modes: int = 0, --tag: string = ""`: The probe in
one mode under a slot cap, every settle dumped and read back.

## def main on-debug

`nu/bin/nuance/fierce/probe/eviction.nu on-debug`, its parameters `mode: string,
out: path, slots: int = 0, --image: string = "", --view: string = "bay",
--cycles: int = 2, --modes: int = 0, --tag: string = ""`: The probe on jab's
debug tree, or on another image beside its kernel and disk.
