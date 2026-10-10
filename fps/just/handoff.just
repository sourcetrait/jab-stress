# TileHandoff's recipes: the debug builds, the handoff fixtures alone,
# the probes, the dump reader's mutants, and the fps readers. Run as
# `just -f fps/just/handoff.just <recipe>`; jab is the checkout beside
# this repository and its target is the SDK's own.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
readers := justfile_directory() / "../readers"
probe := justfile_directory() / "../probe"
mutants := justfile_directory() / "../mutants"

# fps built with the build symbols named, debug unless given
build set="debug":
    nu {{jab}}/sdk/nu/jab.nu build {{jab}}/game/fps --set {{set}}

# the test's sets, the handoff fixtures alone by default
handoff-set set="handoff":
    nu {{jab}}/sdk/nu/jab.nu test {{jab}}/game/fps --set {{set}}

# handoff-holds alone on the debug build, its reading saved beside out
handoff out:
    use {{jab}}/sdk/nu/jab.nu; use {{jab}}/game/fps/test/test.nu [handoff-holds]; let t = (jab target-root {{jab}} | path join debug); let game = '{{jab}}/game/fps'; let s = (date now); let r = (handoff-holds ($t | path join kernel jab.elf) ($t | path join game fps fps.jab) {{out}} DEBUG,COUNT (open ($game | path join content map render_1.nuon)) $game); $r | to nuon --indent 1 | save -f {{out}}/handoff_read.nuon; print $'took ((date now) - $s)'

# builder-holds alone on the debug build
builder out:
    use {{jab}}/sdk/nu/jab.nu; use {{jab}}/game/fps/test/test.nu [builder-holds]; let t = (jab target-root {{jab}} | path join debug); let game = '{{jab}}/game/fps'; let r = (builder-holds ($t | path join kernel jab.elf) ($t | path join game fps fps.jab) {{out}} DEBUG (open ($game | path join content map render_1.nuon)) $game); $r | to nuon --indent 1 | save -f {{out}}/builder.nuon; print ($r | reject by_level | to nuon)

# builder-holds alone on another image
builder-on image out:
    use {{jab}}/sdk/nu/jab.nu; use {{jab}}/game/fps/test/test.nu [builder-holds]; let t = (jab target-root {{jab}} | path join debug); let game = '{{jab}}/game/fps'; let r = (builder-holds ($t | path join kernel jab.elf) {{image}} {{out}} DEBUG (open ($game | path join content map render_1.nuon)) $game); print ($r | reject by_level | to nuon)

# the oblique handoff's residual probe on a handoff map's romfs
oblique spec disk out:
    use {{jab}}/sdk/nu/jab.nu; let t = (jab target-root {{jab}} | path join debug); ^nu {{probe}}/handoff/oblique.nu ($t | path join kernel jab.elf) ($t | path join game fps fps.jab) {{disk}} {{out}} "{{spec}}"

# the held-off pictures of two debug images held byte for byte
identity base handoff_disk still_disk out:
    use {{jab}}/sdk/nu/jab.nu; let t = (jab target-root {{jab}} | path join debug); ^nu {{probe}}/handoff/identity.nu ($t | path join kernel jab.elf) {{base}} ($t | path join game fps fps.jab) {{handoff_disk}} {{still_disk}} {{out}}

# a capture's tile dumps read against the dump alterations
alter-probe api:
    nu {{probe}}/handoff/alter_probe.nu {{api}}

# the dump reader's mutants over a builder capture's dumps
reader-mutants api work:
    nu {{mutants}}/reader_mutants.nu {{jab}}/game/fps/test/tiles.nu {{probe}}/handoff/alter_probe.nu {{api}} {{work}}

# a capture's dumps keyed: each tile's header and its texels' SHA-256
keys api out:
    nu {{jab}}/game/fps/test/tiles.nu keys {{api}} {{out}}

# the pool's counters a frame, the last eight
rows api:
    nu {{probe}}/handoff/rows.nu {{api}}

# the launch's due order, events against a screen
dueprobe:
    nu {{probe}}/handoff/dueprobe.nu

# assertions inside each, for, do, and par-each
assertwrap how:
    nu {{probe}}/nu/assertwrap.nu {{how}}

# the lit loop's steps along a capture's rows
litsteps capture rect ch:
    nu {{probe}}/handoff/litsteps.nu {{capture}} "{{rect}}" {{ch}}

litsteps-live capture rect ch out:
    nu {{jab}}/game/fps/test/tiles.nu lit-steps {{capture}} "{{rect}}" {{ch}} {{out}}

handoff-stats spec index out:
    nu {{jab}}/game/fps/test/tiles.nu handoff {{spec}} {{index}} {{out}}

# the gauge's rules alone, from the checkout or another test.nu
gauge-rules out:
    use {{jab}}/game/fps/test/test.nu [gauge-rules]; gauge-rules {{out}}

gauge-rules-at test out:
    use {{test}} [gauge-rules]; gauge-rules {{out}}

packetgauge mode base out *labels:
    nu {{readers}}/packetgauge.nu {{mode}} {{base}} {{out}} {{labels}}

workergauge mode base out *labels:
    nu {{readers}}/workergauge.nu {{mode}} {{base}} {{out}} {{labels}}

reader script mode base out *labels:
    nu {{script}} {{mode}} {{base}} {{out}} {{labels}}

nucheck file:
    nu-check --as-module {{file}}
