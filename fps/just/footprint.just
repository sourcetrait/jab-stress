# FootprintEstimate's recipes (FrameCeiling), shims over the footprint
# bin until JustRetired: an export's five debug images, a pose set
# captured on them, the captures read, and a pose's differing regions cut
# out.

set shell := ["nu", "-c"]

footprint := justfile_directory() / "../../nu/bin/nuance/fierce/footprint.nu"
data := justfile_directory() / "../../../jab-stress-data"

images export:
    nu {{footprint}} images {{export}}

capture export out only="" poses=(data / "assets" / "fierce" / "poses" / "footprint.nuon"):
    nu {{footprint}} capture {{export}} {{poses}} {{out}} --only '{{only}}'

read out:
    nu {{footprint}} read {{out}}

crops out pose:
    nu {{footprint}} crops {{out}} {{pose}}
