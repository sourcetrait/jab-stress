# footprint.nu

The footprint module's command line, each verb one call of the module,
standalone so its closures run in a nu that loads no other module.

## def main images

`nu/bin/nuance/fierce/footprint.nu images`, its parameters `export: path`: An
export's five debug images built with their kernels and provenance.

## def main capture

`nu/bin/nuance/fierce/footprint.nu capture`, its parameters `export: path,
poses: path, out: path, --only: string = ""`: Each pose captured on every image,
then referenced and differed.

## def main read

`nu/bin/nuance/fierce/footprint.nu read`, its parameters `out: path`: Every
captured pose judged, reading.nuon written.

## def main crops

`nu/bin/nuance/fierce/footprint.nu crops`, its parameters `out: path, pose:
string, --pad: int = 16`: Each region where a pose's pictures differ cut out of
both as PNGs.
