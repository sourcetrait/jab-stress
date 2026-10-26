# footprint.nu

The footprint module's command line, each verb one call of the module,
standalone so its closures run in a nu that loads no other module.

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

## def main reread

`nu/bin/nuance/fierce/footprint.nu reread`, its parameters `tree: path, out:
path, poses: path`: A restored run's poses read again against a pose set, its
reading set beside the first's. The "fps footprint" reader of `nuance.nu
runner reread`, its words `reread {tree} {out} <poses>`.
