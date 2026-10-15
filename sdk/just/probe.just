# The sdl probe's controls (sdk/probe/sdl/controls.nu), run on the Jab
# checkout beside this one: the record under `out`, a new directory, and
# the stripped QEMU under `work`.

set shell := ["nu", "-c"]

controls out work:
    nu {{justfile_directory()}}/../probe/sdl/controls.nu {{out}} {{work}}
