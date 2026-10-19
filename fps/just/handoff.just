# TileHandoff's recipes, shims over the workbench's bins until JustRetired.
# `build` builds fierce, debug unless given. `handoff-set` runs the test's
# sets. `handoff`, `builder`, and `builder-on` run one fixture alone.
# `oblique`, `identity`, `rows`, `dueprobe`, and `litsteps` run the
# probes. `keys`, `litsteps-live`, and `handoff-stats` run jab's tiles bin.
# `packetgauge`, `workergauge`, and `reader` run the readers. `nucheck`
# checks a file as a module. Run as `just -f fps/just/handoff.just
# <recipe>`. jab is the checkout beside this repository, and its target is
# the SDK's own.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
nuance := justfile_directory() / "../../nu/bin/nuance.nu"
bin := justfile_directory() / "../../nu/bin/nuance/fierce"

# fierce built with the build symbols named, debug unless given
build set="debug":
    nu {{nuance}} build {{jab}}/kit/fierce --set {{set}}

# the test's sets, the handoff fixtures alone by default
handoff-set set="handoff":
    nu {{nuance}} test {{jab}}/kit/fierce --set {{set}}

# handoff-holds alone on the debug build, its reading saved beside out
handoff out:
    nu {{bin}}/probe/handoff.nu holds {{out}}

# builder-holds alone on the debug build
builder out:
    nu {{bin}}/probe/handoff.nu builder {{out}}

# builder-holds alone on another image
builder-on image out:
    nu {{bin}}/probe/handoff.nu builder-on {{image}} {{out}}

# the oblique handoff's residual probe on a handoff map's romfs
oblique spec disk out:
    nu {{bin}}/probe/handoff/oblique.nu on-debug "{{spec}}" {{disk}} {{out}}

# the held-off pictures of two debug images held byte for byte
identity base handoff_disk still_disk out:
    nu {{bin}}/probe/handoff/identity.nu on-debug {{base}} {{handoff_disk}} {{still_disk}} {{out}}

# a capture's dumps keyed: each tile's header and its texels' SHA-256
keys api out:
    nu {{nuance}} fierce tiles keys {{api}} {{out}}

# the pool's counters a frame, the last eight
rows api:
    nu {{bin}}/probe/handoff/rows.nu {{api}}

# the launch's due order, events against a screen
dueprobe:
    nu {{bin}}/probe/handoff/due.nu

# the lit loop's steps along a capture's rows
litsteps capture rect ch:
    nu {{bin}}/probe/handoff/litsteps.nu {{capture}} "{{rect}}" {{ch}}

litsteps-live capture rect ch out:
    nu {{nuance}} fierce tiles lit-steps {{capture}} "{{rect}}" {{ch}} {{out}}

handoff-stats spec index out:
    nu {{nuance}} fierce tiles handoff {{spec}} {{index}} {{out}}

packetgauge mode base out *labels:
    nu {{bin}}/packetgauge.nu {{mode}} {{base}} {{out}} {{labels}}

workergauge mode base out *labels:
    nu {{bin}}/workergauge.nu {{mode}} {{base}} {{out}} {{labels}}

reader script mode base out *labels:
    nu {{script}} {{mode}} {{base}} {{out}} {{labels}}

nucheck file:
    nu {{nuance}} check {{file}}
