# mod.nu

A nu file checked as nu reports it: `nu-check --as-module`, its result `true`
or `false`, or with `--ide` `nu --ide-check 50`, its diagnostics as nu prints
them. Its verb: `nu/bin/nuance.nu check <file> [--ide]`. The module form is the
default since `module` is a parser keyword no verb may take.
