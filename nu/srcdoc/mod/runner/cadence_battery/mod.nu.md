# mod.nu

The cadence_battery runner's code, reached by its descriptor through the
workbench bin's `runner` verbs, or run whole by `do.nu bench cadence_battery
<args>`.

## def ready

Before the launch: refuses a `base` that exists or a missing baseline file, then
makes `base`.

## def main

The work: each batch fierce built release and its gauge run three times at its
cadence under `base`, its log `<label>.log`; then each field compared over the
batches' gauge.nuon and the baseline's, `compare_<field>.nuon` and `.txt`;
returns the batches done and each compare's exit.
