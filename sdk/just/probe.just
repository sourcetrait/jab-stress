# The sdl probe's controls (sdk/probe/sdl/controls.nu), run on the Jab
# checkout beside this one: the record under `out`, a new directory, and
# the stripped QEMU under `work`.

set shell := ["nu", "-c"]

controls out work:
    nu {{justfile_directory()}}/../probe/sdl/controls.nu {{out}} {{work}}

# Nothing is run and nothing written, and any discrepancy exits non-zero.
# A controls run's record, its directory, read again by the current reader.
reread record:
    nu {{justfile_directory()}}/../probe/sdl/controls.nu reread {{record}}
