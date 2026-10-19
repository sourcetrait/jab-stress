# Runner.nutype

The shape of a runner's descriptor, `nu/nuon/runner/<harness>.nuon`: the
nonce of the run the body last ran as, which `rerun` reaches while the
server's cache holds it; a title; the body's argument and result types as
nushell writes them, from which a `run` call's schemas are written; and the
body, the long engine's launch alone.
