# TileEviction's planning probes, shims over the workbench's bins until
# JustRetired: the pool's counters a frame from a capture, and the
# alternate views under a slot cap with a dump at every settle.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
probe := justfile_directory() / "../../nu/bin/nuance/fierce/probe"

rows api:
    nu {{probe}}/eviction/rows.nu {{api}}

# a pair run read against a views run's key sets, the views by index
pair-read pair sets a="0" b="4":
    nu {{probe}}/eviction/pair.nu {{pair}} {{sets}} {{a}} {{b}}

# mode sets, views, lift, budget, building, or quota; slots the cap, 0 for every slot
probe mode out slots="0":
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{probe}}/eviction.nu ($t | path join kernel jab.elf) ($t | path join kit fierce fierce.jab) ($t | path join kit fierce still.romfs) {{out}} {{mode}} {{slots}}

# the same on another debug image, a candidate's
probe-on image mode out slots="0":
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{probe}}/eviction.nu ($t | path join kernel jab.elf) {{image}} ($t | path join kit fierce still.romfs) {{out}} {{mode}} {{slots}}

# the join's hold: W 2 in fixed bands, J holding worker 2 until the
# round's join releases it (flags: --no-hold for the unheld control)
hold out name="hold" *flags:
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{probe}}/hold.nu ($t | path join kernel jab.elf) ($t | path join kit fierce fierce.jab) ($t | path join kit fierce still.romfs) {{out}} --name {{name}} {{flags}}

# the same on another debug image, a candidate's
hold-on image out name="hold" *flags:
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{probe}}/hold.nu ($t | path join kernel jab.elf) {{image}} ($t | path join kit fierce still.romfs) {{out}} --name {{name}} {{flags}}

# the spawn view and another settled view in turn, cycles of both, every
# settle dumped; modes the O frame's (4 the stale entries), tag the run's
pair image out slots view="bay" cycles="2" modes="0" tag="":
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{probe}}/eviction.nu ($t | path join kernel jab.elf) {{image}} ($t | path join kit fierce still.romfs) {{out}} pair {{slots}} --view {{view}} --cycles {{cycles}} --modes {{modes}} --tag "{{tag}}"
