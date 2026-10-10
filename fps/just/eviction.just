# TileEviction's planning probes: the pool's counters a frame from a
# capture, and the alternate views under a slot cap with a dump at every
# settle.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
probe := justfile_directory() / "../probe"

rows api:
    nu {{probe}}/eviction/rows.nu {{api}}

# a pair run read against a views run's key sets, the views by index
pair-read pair sets a="0" b="4":
    nu {{probe}}/eviction/pair_read.nu {{pair}} {{sets}} {{a}} {{b}}

# mode sets, views, lift, or budget; slots the cap, 0 for every slot
probe mode out slots="0":
    use {{jab}}/sdk/nu/jab.nu; let t = (jab target-root {{jab}} | path join debug); ^nu {{probe}}/eviction/probe.nu ($t | path join kernel jab.elf) ($t | path join game fps fps.jab) ($t | path join game fps still.romfs) {{out}} {{mode}} {{slots}}

# the same on another debug image, a candidate's
probe-on image mode out slots="0":
    use {{jab}}/sdk/nu/jab.nu; let t = (jab target-root {{jab}} | path join debug); ^nu {{probe}}/eviction/probe.nu ($t | path join kernel jab.elf) {{image}} ($t | path join game fps still.romfs) {{out}} {{mode}} {{slots}}

# the spawn view and another settled view in turn, cycles of both, every
# settle dumped; modes the O frame's (4 the stale entries), tag the run's
pair image out slots view="bay" cycles="2" modes="0" tag="":
    use {{jab}}/sdk/nu/jab.nu; let t = (jab target-root {{jab}} | path join debug); ^nu {{probe}}/eviction/probe.nu ($t | path join kernel jab.elf) {{image}} ($t | path join game fps still.romfs) {{out}} pair {{slots}} --view {{view}} --cycles {{cycles}} --modes {{modes}} --tag "{{tag}}"
