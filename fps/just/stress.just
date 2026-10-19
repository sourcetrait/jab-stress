# The release tier's fixtures, shims over the workbench's bins until
# JustRetired: exhaustive tests of jab's fierce run on a debug image, apart
# from jab's own suite. Run as `just -f fps/just/stress.just <recipe>`; jab
# is the checkout beside this repository and its target is the SDK's own.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
eviction := justfile_directory() / "../../nu/bin/nuance/fierce/stress/eviction.nu"

# the tile eviction fixtures on a debug image, all or those named
eviction image out *fixtures:
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{eviction}} ($t | path join kernel jab.elf) {{image}} ($t | path join kit fierce still.romfs) {{out}} {{fixtures}}

# the same on the checkout's own debug build
eviction-debug out *fixtures:
    use {{jab}}/nu/mod/target; let t = (target root {{jab}} | path join debug); ^nu {{eviction}} ($t | path join kernel jab.elf) ($t | path join kit fierce fierce.jab) ($t | path join kit fierce still.romfs) {{out}} {{fixtures}}
