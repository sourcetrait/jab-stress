# freeze.nu

The freeze module's command line, each verb one call of the module, standalone
so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/freeze.nu`, its parameters `repo: string, commit: string,
cands: string, expected: string, --set: string = "", --program: string = "",
--debug`: A commit's program exported and built release, or debug with
`--debug`, gated, its provenance kept.

## def main launcher

`nu/bin/nuance/fierce/freeze.nu launcher`, its parameters `repo: string, out:
path`: The launcher a freeze's measurements run under, written once to `out`.
