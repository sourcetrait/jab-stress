# timing.nu

The timing module's command line, each verb one call of the module, standalone
so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/kernel/timing.nu`, its parameters `readings: path, out: path`:
The decision over one readings record, written as decision.nuon.

## def "main calibrate"

`nu/bin/nuance/kernel/timing.nu calibrate`, its parameters `base: path, out:
path`: eps from a calibration capture's runs, written as calibration.nuon.

## def "main readings"

`nu/bin/nuance/kernel/timing.nu readings`, its parameters `spec: path, out:
path`: the readings a comparison's captures give, from a spec, written as
readings.nuon (the readings module).

## def "main package"

`nu/bin/nuance/kernel/timing.nu package`, its parameters `spec: path, out:
path, --stage: string`: JointTiming's host package from a readings spec's
freeze and jab's benches, one tar (the package module).
