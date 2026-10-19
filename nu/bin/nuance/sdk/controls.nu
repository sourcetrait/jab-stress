#!/usr/bin/env nu
# The controls module's path, bound at parse time
const CONTROLS = path self ../../../mod/nuance/sdk/controls
use $CONTROLS

# The controls run, one NUON record kept under `out` and printed
def main [out: path, work: path] {
    controls $out $work
}

# A controls run's record reread by the current reader, nothing run
def "main reread" [record: path] {
    controls reread $record
}
