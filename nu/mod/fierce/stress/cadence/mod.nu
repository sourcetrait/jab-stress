use (path self ../../../../../../jab/kit/fierce/nu/mod/suite/clock) [cadence-holds]

# The game's directory in jab, checked out beside the workbench
const GAME = (path self ../../../../../../jab/kit/fierce | path expand)

# The cadence fixtures alone on a debug image, `cadence: ok` once they hold
export def main [kernel: path, image: path, out: path, --set: string = "DEBUG"]: nothing -> nothing {
    let game = $GAME
    mkdir $out
    cadence-holds $kernel $image $out $set $game
    print "cadence: ok"
}
