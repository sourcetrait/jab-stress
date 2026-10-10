# TileEviction's planning probes: the pool's counters a frame from a
# capture, and the alternate views under a slot cap with a dump at every
# settle.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
probe := justfile_directory() / "../probe"

rows api:
    nu {{probe}}/eviction/rows.nu {{api}}

# mode sets, views, lift, or budget; slots the cap, 0 for every slot
probe mode out slots="0":
    use {{jab}}/sdk/nu/jab.nu; let t = (jab target-root {{jab}} | path join debug); ^nu {{probe}}/eviction/probe.nu ($t | path join kernel jab.elf) ($t | path join game fps fps.jab) ($t | path join game fps still.romfs) {{out}} {{mode}} {{slots}}
