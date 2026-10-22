# mod.nu

The cadence fixtures alone on a debug image of jab's fps: suite/clock's
cadence-holds, CadenceSchedule at cadences 0, 1, and 2 and MotionByTime, each a
launch measured from its records, the fixtures building their own Render One and
still Render Zero disks under `out`. Prints `cadence: ok` once every fixture
holds.

`--set` names the build's symbols as the fixtures read them, `DEBUG` unless
given: with `P2` among them, the fixtures hold each presented flip to P2's rule
and K at the kernel's FRAME_EPS (`p2-holds`), the image and kernel built under
the same symbols, as `./do build kit/fierce --set debug,p2` builds them.

Its bin: `nu/bin/nuance/fierce/stress/cadence.nu <kernel> <image> <out>
[--set DEBUG,P2]`.
