# handoff.nu

The handoff probe's module's command line, each verb one call of the module,
standalone so its closures run in a nu that loads no other module.

## def main holds

`nu/bin/nuance/fierce/probe/handoff.nu holds`, its parameters `out: path`:
handoff-holds alone on the debug tree, its reading saved and its time printed.

## def main builder

`nu/bin/nuance/fierce/probe/handoff.nu builder`, its parameters `out: path`:
builder-holds alone on the debug tree, its reading saved and printed.

## def main builder-on

`nu/bin/nuance/fierce/probe/handoff.nu builder-on`, its parameters `image: path,
out: path`: builder-holds alone on another image beside the debug kernel,
printed.
