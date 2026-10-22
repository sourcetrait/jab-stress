#!/usr/bin/env nu
# The fresh build's module's path, bound at parse time
const FRESHBUILD = path self ../mod/nuance/freshbuild
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
# The runners' dispatcher's path, bound at parse time
const RUNNER = path self ../mod/runner
# The run landing's module's path, bound at parse time
const LANDING = path self ../mod/runner/landing
# The log container's module's path, bound at parse time
const LOG = path self ../mod/runner/log
use $FRESHBUILD
use $RECORD
use $HOT
use $JAB
use $CHECK
use $TILES
use $CENSUS
use $RUNNER
use $LANDING
use $LOG

# A fresh build of jab's matrix from its HEAD, each artifact's digest in `out`.
def "main freshbuild manifest" [jab: path, out: path] {
    freshbuild manifest $jab $out
}

# A manifest taken after the moves held to one taken before, by role.
def "main freshbuild compare" [before: path, after: path, jab: path] {
    freshbuild compare $before $after $jab
}

# A harness's checks before its long launch, its NUON arguments in and out.
def "main runner ready" [harness: string, given: string] {
    runner ready $harness $given
}

# A harness's work inside its long launch, NUON arguments in, its result out.
def "main runner work" [harness: string, given: string] {
    runner work $harness $given
}

# A run's directory landed in the data checkout, its archive kept, checked
def "main runner land" [dir: path, subject: string, set: string, stamp: string, manifest: path, --data: string = "", --source: string = ""] {
    landing land $dir $subject $set $stamp $manifest --data $data --source $source
}

# A schema 1 run moved to schema 2 with its further originals, a receipt written.
def "main runner migrate" [run: path, manifest: path, scratch: path, --data: string = ""] {
    landing migrate $run $manifest $scratch --data $data
}

# A landed run laid out in `scratch` as its runner wrote it, with its receipt.
def "main runner restore" [run: path, scratch: path, --root: string = ""] {
    landing restore $run $scratch --root $root
}

# A landed run reread by a reader's command over its restoration in `scratch`.
def "main runner reread" [run: path, scratch: path, reader: string, bin: path, ...words: string] {
    landing reread $run $scratch $reader $bin ...$words
}

# A log container's original bytes, refused unless whole.
def "main runner log bytes" [container: path] {
    log original $container
}

# A log container's original as text, refused unless whole.
def "main runner log text" [container: path] {
    log text $container
}

# A landed run's problems, none where it holds.
def "main runner record stored" [run: path, --root: string = ""] {
    record stored $run --root $root
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

def main [] { help main }
