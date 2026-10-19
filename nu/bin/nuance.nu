#!/usr/bin/env nu
# The fresh build's module's path, bound at parse time
const FRESHBUILD = path self ../mod/nuance/freshbuild
# The import map's module's path, bound at parse time
const IMPORTMAP = path self ../mod/nuance/importmap
# The run records' module's path, bound at parse time
const RECORD = path self ../mod/runner/record
use $FRESHBUILD
use $IMPORTMAP
use $RECORD

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

# A landed run's problems, none where it holds.
def "main runner record stored" [run: path] {
    record stored $run
}

# A restoration's problems against its run, none where it holds.
def "main runner record restored" [dir: path] {
    record restored $dir
}

# A reader's required inputs a restoration lacks, none where all are there.
def "main runner record required" [dir: path, reader: string] {
    record required $dir $reader
}

def main [] { help main }
