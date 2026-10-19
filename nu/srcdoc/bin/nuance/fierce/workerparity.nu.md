# workerparity.nu

The workerparity module's command line, each verb one call of the module,
standalone so its closures run in a nu that loads no other module.

## def main

`nu/bin/nuance/fierce/workerparity.nu`, its parameters `kernel: path, image:
path, out: path, --set: string = "debug", --poses: string = "spawn,bay,up",
--modes: string = "0:0,2:0,1:0,2:16", --map: string = "render_0", --harts: int =
4, --bootargs: string = "", --cancel`: A still copy's views drawn by each mode
and judged against W 0's.

## def main judge

`nu/bin/nuance/fierce/workerparity.nu judge`, its parameters `out: path,
--cancel, --harts: int = 4, --bootargs: string = ""`: A parity judged again from
its recorded launches, the old verdict kept.

## def main fault

`nu/bin/nuance/fierce/workerparity.nu fault`, its parameters `kernel: path,
image: path, out: path, --set: string = "debug", --pose: string = "spawn",
--modes: string = "1:0,2:0,3:0,4:0,5:0,6:0,7:0", --map: string = "render_0",
--harts: int = 8, --bootargs: string = "", --started: string = ""`: A worker's
fault at each count, the run ended through the kernel.
