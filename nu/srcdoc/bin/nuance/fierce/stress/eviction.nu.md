# eviction.nu

The eviction module's command line, each verb one call of the module, standalone
so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/stress/eviction.nu`, its parameters `kernel: path, image:
path, disk: path, out: path, ...fixtures: string`: The eviction fixtures named,
every one by default, each result kept.

## def main on-debug

`nu/bin/nuance/fierce/stress/eviction.nu on-debug`, its parameters `out: path,
...fixtures: string, --image: string = ""`: The fixtures on jab's debug tree, or
another image beside its kernel and disk.
