# walk.nu

The walk module's command line, each verb one call of the module, standalone so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/kernel/walk.nu`, its parameters `probe: path, out: path, --eps: int = 10000`: a probed run's bundle checked and its guest's side read, saved.

## def main guest

`nu/bin/nuance/kernel/walk.nu guest`, its parameters `run: path, out: path, --eps: int = 10000`: an unprobed run read from its own records, guest-only, saved.

## def main replay-of

`nu/bin/nuance/kernel/walk.nu replay-of`, its parameters `run: path, stream: path`: a replay stream written from a run's own records.
