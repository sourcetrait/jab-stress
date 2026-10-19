#!/usr/bin/env nu
# The fresh build's module's path, bound at parse time
const FRESHBUILD = path self ../mod/nuance/freshbuild
# The import map's module's path, bound at parse time
const IMPORTMAP = path self ../mod/nuance/importmap
# The run records' module's path, bound at parse time
const RECORD = path self ../mod/runner/record
# The hot routines' probe's module's path, bound at parse time
const HOT = path self ../mod/nuance/fierce/probe/hot
# jab's drivers' module's path, bound at parse time
const JAB = path self ../mod/nuance/jab
# The file check's module's path, bound at parse time
const CHECK = path self ../mod/nuance/check
# jab's tiles bin's module's path, bound at parse time
const TILES = path self ../mod/nuance/fierce/tiles
# The census's module's path, bound at parse time
const CENSUS = path self ../mod/nuance/fierce/census
use $FRESHBUILD
use $IMPORTMAP
use $RECORD
use $HOT
use $JAB
use $CHECK
use $TILES
use $CENSUS

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

# The renderer's hot routines' places in an ELF, printed as NUON.
def "main hot" [elf: string] {
    hot $elf
}

# A directory built by jab's driver with the build symbols named.
def "main build" [dir: path, --set: string = ""] {
    jab build $dir --set $set
}

# A directory's tests run by jab's driver with the build symbols named.
def "main test" [dir: path, --set: string = ""] {
    jab test $dir --set $set
}

# A file checked as a module, or by nu's IDE check with --ide.
def "main check" [file: path, --ide] {
    check $file --ide=$ide
}

# A capture's dumps keyed by tile header and texels' SHA-256, by jab's bin.
def "main fierce tiles keys" [api: path, out: path] {
    tiles keys $api $out
}

# The lit loop's most step between side-by-side pixels, by jab's bin.
def "main fierce tiles lit-steps" [capture: path, rect: string, crosshair: int, out: path] {
    tiles lit-steps $capture $rect $crosshair $out
}

# The handoff pair at `index` compared, by jab's bin.
def "main fierce tiles handoff" [spec: path, index: int, out: path] {
    tiles handoff $spec $index $out
}

# The census reader's holds over a serial log by a jab tree's census module.
def "main fierce census reader-holds" [tree: path, serial: path] {
    census reader-holds $tree $serial
}

# fierce's gauge module loaded alone in a nu of its own.
def "main fierce census gauge-load" [] {
    census gauge-load
}

def main [] { help main }
