# identity_corrections.nu

The identity_corrections module's command line, each verb one call of the
module, standalone so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/identity_corrections.nu`, its parameters `base: string,
release_flags_file: string, nm: string, out: string, ...batteries: string`: Each
battery identity checked, its correction written and read back.
