# FootprintEstimate's recipes (FrameCeiling): an export's five debug
# images, a pose set captured on them, the captures read, and a pose's
# differing regions cut out, through footprint.nu.

set shell := ["nu", "-c"]

readers := justfile_directory() / "../readers"
data := justfile_directory() / "../../../jab-stress-data"

images export:
    nu {{readers}}/footprint.nu images {{export}}

capture export out only="" poses=(data / "assets" / "fierce" / "poses" / "footprint.nuon"):
    nu {{readers}}/footprint.nu capture {{export}} {{poses}} {{out}} --only '{{only}}'

read out:
    nu {{readers}}/footprint.nu read {{out}}

crops out pose:
    nu {{readers}}/footprint.nu crops {{out}} {{pose}}
