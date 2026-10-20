#!/usr/bin/env nu
# The timing module's path, bound at parse time
const TIMING = path self ../../../mod/kernel/timing
# The readings assembler's path, bound at parse time
const READINGS = path self ../../../mod/kernel/timing/readings
# The host package's path, bound at parse time
const PACKAGE = path self ../../../mod/kernel/timing/package
use $TIMING
use $READINGS
use $PACKAGE

# The decision over one readings record, written as decision.nuon
def main [readings: path, out: path] {
    timing $readings $out
}

# eps from a calibration capture's runs, written as calibration.nuon
def "main calibrate" [base: path, out: path] {
    timing calibrate $base $out
}

# The readings a comparison's captures give, from a spec, written as readings.nuon
def "main readings" [spec: path, out: path] {
    readings $spec $out
}

# JointTiming's host package from a readings spec's freeze and jab's benches, one tar
def "main package" [spec: path, out: path, --stage: string = ""] {
    package $spec $out --stage $stage
}
