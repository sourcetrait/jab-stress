# hold.nu

The hold module's command line, each verb one call of the module, standalone so
its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/probe/hold.nu`, its parameters `kernel: path, image: path,
disk: path, out: path, --name: string = "hold", --no-hold, --seconds: int = 8,
--no-capture`: W 2 in fixed bands with worker 2 held to the join, or unheld,
read back.

## def main on-debug

`nu/bin/nuance/fierce/probe/hold.nu on-debug`, its parameters `out: path,
--image: string = "", --name: string = "hold", --no-hold, --seconds: int = 8,
--no-capture`: The hold on jab's debug tree, or on another image beside its
kernel and disk.
