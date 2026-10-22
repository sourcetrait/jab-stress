#!/usr/bin/env nu
# This file's directory, the root's do link resolved
const HERE = (path self | path expand | path dirname)
# The runners' dispatcher's path, bound at parse time
const RUNNER = ($HERE | path join ../mod/runner | path expand)
use $RUNNER

# The workbench's root, two directories above this file's
const STRESS = ($HERE | path join ../.. | path expand)

# A battery, a runner's harness, run whole on its arguments' NUON file
def "main bench" [battery: string, args: path] {
    runner bench $battery $args $STRESS
}

# The bin's help, its verbs listed, when called with no verb
def main [] { help main }
