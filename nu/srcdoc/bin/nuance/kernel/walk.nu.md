# walk.nu

The walk module's command line, each verb one call of the module, standalone so
its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/kernel/walk.nu`, its parameters `probe: path, out: path, --eps:
int = 10000, --replay: path`: A probed run read paired, saved.

## def main guest

`nu/bin/nuance/kernel/walk.nu guest`, its parameters `run: path, out: path,
--eps: int = 10000, --replay: path`: An unprobed run read from its own records,
guest-only, saved.

## def main guest-runs

`nu/bin/nuance/kernel/walk.nu guest-runs`, its parameters `tree: path, out:
path, --eps: int = 10000`: Every run under a set's tree read guest-only, each
saved as `<name>.guest.nuon`.

## def main replay-of

`nu/bin/nuance/kernel/walk.nu replay-of`, its parameters `run: path, stream:
path`: A replay stream written from a run's own records.
