#!/usr/bin/env nu
# The handoff probe's module's path, bound at parse time
const HANDOFF = path self ../../../../mod/nuance/fierce/probe/handoff
use $HANDOFF

# handoff-holds alone on the debug tree, its reading saved and its time printed
def "main holds" [out: path] {
    handoff holds $out
}

# builder-holds alone on the debug tree, its reading saved and printed
def "main builder" [out: path] {
    handoff builder $out
}

# builder-holds alone on another image beside the debug kernel, printed
def "main builder-on" [image: path, out: path] {
    handoff builder-on $image $out
}

# The bin's help, its verbs listed, when called with no verb
def main [] { help main }
