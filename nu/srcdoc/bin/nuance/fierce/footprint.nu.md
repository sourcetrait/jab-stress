# footprint.nu

The footprint module's command line, each verb one call of the module,
standalone so its closures run in a nu that loads no other module.

## def main images

`nu/bin/nuance/fierce/footprint.nu images`, its parameters `export: path`: An
export's debug images built with their kernels, provenance, and IZ_MIN.

## def main capture

`nu/bin/nuance/fierce/footprint.nu capture`, its parameters `export: path,
poses: path, out: path, --only: string = ""`: Each pose captured on its kind's
images, then referenced and differed.

## def main read

`nu/bin/nuance/fierce/footprint.nu read`, its parameters `out: path, poses:
path`: Every captured pose judged against the pose set, reading.nuon written.

## def main clamp-plan

`nu/bin/nuance/fierce/footprint.nu clamp-plan`, its parameters `dir: path,
surface: int, --owner: string = "owner", --levels: string = "levels"`: The
clamp's threshold and witnesses planned over a captured pose.

## def main crops

`nu/bin/nuance/fierce/footprint.nu crops`, its parameters `out: path, pose:
string, --pad: int = 16`: Each region where a pose's pictures differ cut out of
both as PNGs.
