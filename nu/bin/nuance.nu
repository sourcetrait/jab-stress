#!/usr/bin/env nu
# The fresh build's module's path, bound at parse time
const FRESHBUILD = path self ../mod/nuance/freshbuild
# The import map's module's path, bound at parse time
const IMPORTMAP = path self ../mod/nuance/importmap
use $FRESHBUILD
use $IMPORTMAP

# A fresh build of jab's matrix from its HEAD, each artifact's digest in `out`.
def "main freshbuild manifest" [jab: path, out: path] {
    freshbuild manifest $jab $out
}

# A manifest taken after the moves held to one taken before, by role.
def "main freshbuild compare" [before: path, after: path, jab: path] {
    freshbuild compare $before $after $jab
}

# jab's and the workbench's trees held to the migration contract.
def "main importmap check" [
    jab: path, stress: path, --landed: string = '', --contract: string = '', --out: string = ''
] {
    importmap check $jab $stress --landed $landed --contract $contract --out $out
}

def main [] { help main }
