# The cadence fixtures alone on a debug image of jab's fps: suite/clock's
# cadence-holds, CadenceSchedule at cadences 0, 1, and 2 and MotionByTime,
# each a launch measured from its records, the fixtures building their own
# Render One and still Render Zero disks under `out`. Prints `cadence: ok`
# once every fixture holds.
#
# Run as `nu cadence.nu <kernel> <image> <out>`.
use ../../../jab/kit/fierce/nu/mod/suite/clock [cadence-holds]

def main [kernel: path, image: path, out: path] {
    let game = ($env.FILE_PWD | path join ".." ".." ".." "jab" "kit" "fierce" | path expand)
    mkdir $out
    cadence-holds $kernel $image $out "DEBUG" $game
    print "cadence: ok"
}
