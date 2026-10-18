#!/usr/bin/env nu
use ../mod/nuance/freshbuild
use ../mod/nuance/importmap

# A fresh build of jab's matrix from its HEAD, each artifact's digest in `out`.
def "main freshbuild manifest" [jab: path, out: path] {
    freshbuild manifest $jab $out
}

# jab's and the workbench's trees held to the migration contract.
def "main importmap check" [
    jab: path, stress: path, --landed: string = '', --contract: string = '', --out: string = ''
] {
    importmap check $jab $stress --landed $landed --contract $contract --out $out
}

def main [] { help main }
