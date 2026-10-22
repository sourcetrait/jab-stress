#!/usr/bin/env nu
# The import map's module's path, bound at parse time
const IMPORTMAP = path self ../../mod/nuance/importmap
use $IMPORTMAP

# jab's and the workbench's trees held to the migration contract
def "main check" [jab: path, stress: path, --landed: string = '', --contract: string = '', --out: string = ''] {
    importmap check $jab $stress --landed $landed --contract $contract --out $out
}

# The bin's help, its verbs listed, when called with no verb
def main [] { help main }
