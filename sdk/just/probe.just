# The sdl probe's controls, a shim over the controls bin until
# JustRetired, run on the Jab checkout beside this one: the record under
# `out`, a new directory, and the stripped QEMU under `work`.

set shell := ["nu", "-c"]

controls := justfile_directory() / "../../nu/bin/nuance/sdk/controls.nu"

controls out work:
    nu {{controls}} {{out}} {{work}}

# Nothing is run and nothing written, and any discrepancy exits non-zero.
# A controls run's record, its directory, read again by the current reader.
reread record:
    nu {{controls}} reread {{record}}
