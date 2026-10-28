# mod.nu

The runners' dispatcher: every harness module by its name, the boundary
between the long engine's descriptors in `nu/nuon/runner/` and the code they
run. A descriptor's definition holds the engine alone and reaches a harness
through the workbench bin, `nuance.nu runner ready|work <harness> <args>`, its
arguments NUON on the command line and its answer NUON on stdout; so no module
imports the engine's rig, every module parses and runs under plain nu, and no
descriptor names a box path. `record`, the run records' validator, is a child
of its own, imported directly.

## def said

An error's messages as plain text: each message nu's renderer drew, its
wrapped lines joined, then any help, the lines that name the failure, without
the source excerpt.

## def ready

The harness's checks before its launch, its directories made and the values
its progress check reads returned as NUON; a refusal its message on stderr,
exit 1, which the descriptor raises before anything launches.

## def work

The harness's work, its result as NUON on stdout, the record the long
engine's result packet carries; a failure its message on stderr, exit 1.

## def bench

A battery run whole in the foreground, `do.nu bench <battery> <args>`: its
arguments read from a NUON file, `stress` set to the workbench, its ready
then its work, the result printed as NUON. A refusal or a failure raises as
nu renders it.
