# The release tier's fixtures: exhaustive tests of jab's fps run on a
# debug image, apart from jab's own suite. Run as
# `just -f fps/just/stress.just <recipe>`; jab is the checkout beside
# this repository and its target is the SDK's own.

set shell := ["nu", "-c"]

jab := justfile_directory() / "../../../jab"
stress := justfile_directory() / "../stress"
runners := justfile_directory() / "../../runners"
data := justfile_directory() / "../../../jab-stress-data"

# Qualification's stress manifest: every mutant set and harness by its
# bytes and SHA-256, every find held to match once, into out
manifest out:
    nu {{runners}}/manifest.nu {{jab}} {{data}} {{out}}

# the manifest's own fixtures on mirrors of the sets under scratch
manifest-holds scratch:
    nu {{runners}}/manifest.nu holds {{jab}} {{data}} {{scratch}}

# the tile eviction fixtures on a debug image, all or those named
eviction image out *fixtures:
    use {{jab}}/sdk/nu/jab.nu; let t = (jab target-root {{jab}} | path join debug); ^nu {{stress}}/eviction.nu ($t | path join kernel jab.elf) {{image}} ($t | path join game fps still.romfs) {{out}} {{fixtures}}

# the same on the checkout's own debug build
eviction-debug out *fixtures:
    use {{jab}}/sdk/nu/jab.nu; let t = (jab target-root {{jab}} | path join debug); ^nu {{stress}}/eviction.nu ($t | path join kernel jab.elf) ($t | path join game fps fps.jab) ($t | path join game fps still.romfs) {{out}} {{fixtures}}
