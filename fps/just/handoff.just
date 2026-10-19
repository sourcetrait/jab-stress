# TileHandoff's recipes. `build` builds fps, debug unless given.
# `handoff-set` runs the test's sets. `handoff`, `builder`, and
# `builder-on` run one fixture alone. `oblique`, `identity`, `rows`,
# `dueprobe`, and `litsteps` run the probes. `keys`, `litsteps-live`, and
# `handoff-stats` run jab's tiles.nu. `packetgauge`, `workergauge`, and
# `reader` run the fps readers. `nucheck` checks a file as a module.
# Run as `just -f fps/just/handoff.just <recipe>`. jab is the checkout
# beside this repository, and its target is the SDK's own.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
readers := justfile_directory() / "../readers"
probe := justfile_directory() / "../probe"

# fps built with the build symbols named, debug unless given
build set="debug":
    nu {{jab}}/nu/bin/do.nu build {{jab}}/kit/fierce --set {{set}}

# the test's sets, the handoff fixtures alone by default
handoff-set set="handoff":
    nu {{jab}}/nu/bin/do.nu test {{jab}}/kit/fierce --set {{set}}

# handoff-holds alone on the debug build, its reading saved beside out
handoff out:
    use {{jab}}/nu/mod/target; use {{jab}}/kit/fierce/test/test.nu [handoff-holds]; let t = (target root {{jab}} | path join debug); let game = '{{jab}}/kit/fierce'; let s = (date now); let r = (handoff-holds ($t | path join kernel jab.elf) ($t | path join kit fierce fierce.jab) {{out}} DEBUG,COUNT (open ($game | path join content map render_1.nuon)) $game); $r | to nuon --indent 1 | save -f {{out}}/handoff_read.nuon; print $'took ((date now) - $s)'

# builder-holds alone on the debug build
builder out:
    use {{jab}}/nu/mod/target; use {{jab}}/kit/fierce/test/test.nu [builder-holds]; let t = (target root {{jab}} | path join debug); let game = '{{jab}}/kit/fierce'; let r = (builder-holds ($t | path join kernel jab.elf) ($t | path join kit fierce fierce.jab) {{out}} DEBUG (open ($game | path join content map render_1.nuon)) $game); $r | to nuon --indent 1 | save -f {{out}}/builder.nuon; print ($r | reject by_level | to nuon)

# builder-holds alone on another image
builder-on image out:
    use {{jab}}/nu/mod/target; use {{jab}}/kit/fierce/test/test.nu [builder-holds]; let t = (target root {{jab}} | path join debug); let game = '{{jab}}/kit/fierce'; let r = (builder-holds ($t | path join kernel jab.elf) {{image}} {{out}} DEBUG (open ($game | path join content map render_1.nuon)) $game); print ($r | reject by_level | to nuon)

# the oblique handoff's residual probe on a handoff map's romfs
oblique spec disk out:
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{probe}}/handoff/oblique.nu ($t | path join kernel jab.elf) ($t | path join kit fierce fierce.jab) {{disk}} {{out}} "{{spec}}"

# the held-off pictures of two debug images held byte for byte
identity base handoff_disk still_disk out:
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{probe}}/handoff/identity.nu ($t | path join kernel jab.elf) {{base}} ($t | path join kit fierce fierce.jab) {{handoff_disk}} {{still_disk}} {{out}}

# a capture's dumps keyed: each tile's header and its texels' SHA-256
keys api out:
    nu {{jab}}/kit/fierce/test/tiles.nu keys {{api}} {{out}}

# the pool's counters a frame, the last eight
rows api:
    nu {{probe}}/handoff/rows.nu {{api}}

# the launch's due order, events against a screen
dueprobe:
    nu {{probe}}/handoff/dueprobe.nu

# the lit loop's steps along a capture's rows
litsteps capture rect ch:
    nu {{probe}}/handoff/litsteps.nu {{capture}} "{{rect}}" {{ch}}

litsteps-live capture rect ch out:
    nu {{jab}}/kit/fierce/test/tiles.nu lit-steps {{capture}} "{{rect}}" {{ch}} {{out}}

handoff-stats spec index out:
    nu {{jab}}/kit/fierce/test/tiles.nu handoff {{spec}} {{index}} {{out}}

packetgauge mode base out *labels:
    nu {{readers}}/packetgauge.nu {{mode}} {{base}} {{out}} {{labels}}

workergauge mode base out *labels:
    nu {{readers}}/workergauge.nu {{mode}} {{base}} {{out}} {{labels}}

reader script mode base out *labels:
    nu {{script}} {{mode}} {{base}} {{out}} {{labels}}

nucheck file:
    nu-check --as-module {{file}}
