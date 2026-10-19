# importmap.nu

The import map's module's command line, standalone so its closures run in a
nu that loads no other module: under `nu/bin/nuance.nu`, whose imports a
closure command copies each time it runs, the checker took 86 seconds over
the trees where alone it takes 47.

## def main check

`nu nu/bin/nuance/importmap.nu check <jab> <stress> [--landed <groups>]
[--contract <file>] [--out <dir>]`: the import-map checker over both live
trees, the groups landed as one comma-separated string, since a script's
command line carries no list.
