# mod.nu

JoinBeforeBoundary's probe: the still disk's spawn view drawn by W 2 in fixed
bands, one band a worker, with the J frame holding hart 2's worker, the round's
position 1, until the round's join releases it (byte 14), or with `--no-hold`
the same run unheld. Read back: the guest's status, the UART's fps lines, and
the frames' rounds after the J, each round's slowest worker against every
worker's busy time: a held round's slowest is about the whole of it, since the
held worker's band waits on the other's join, where an unheld round's is about
half.

## def jobs-frame

The console's J frame: the delayed worker's hart in byte 4, its delay in
microseconds from byte 8, the cancel in byte 12, the faulting worker's
hart in byte 13, and the hold in byte 14.

## def main

- with --no-capture no screen ends the run: it ends at the guest's exit
  or the bound, so a late exit's status comes back
