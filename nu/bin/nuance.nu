#!/usr/bin/env nu
use ../mod/nuance/freshbuild

# A fresh build of jab's matrix from its HEAD, each artifact's digest in `out`.
def "main freshbuild manifest" [jab: path, out: path] {
    freshbuild manifest $jab $out
}

def main [] { help main }
