# The release tier's fixtures, shims over the workbench's bins until
# JustRetired: exhaustive tests of jab's fierce run on a debug image, apart
# from jab's own suite. Run as `just -f fps/just/stress.just <recipe>`; jab
# is the checkout beside this repository and its target is the SDK's own.

set shell := ["nu", "-c"]

eviction := justfile_directory() / "../../nu/bin/nuance/fierce/stress/eviction.nu"

# the tile eviction fixtures on a debug image, all or those named
eviction image out *fixtures:
    nu {{eviction}} on-debug {{out}} {{fixtures}} --image {{image}}

# the same on the checkout's own debug build
eviction-debug out *fixtures:
    nu {{eviction}} on-debug {{out}} {{fixtures}}
