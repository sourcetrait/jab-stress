# timing.nu

The timing module's command line, each verb one call of the module, standalone
so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/kernel/timing.nu`, its parameters `readings: path, out: path`:
The decision over one readings record, written as decision.nuon.

## def "main calibrate"

`nu/bin/nuance/kernel/timing.nu calibrate`, its parameters `base: path, out:
path`: eps from a calibration capture's runs, written as calibration.nuon.
