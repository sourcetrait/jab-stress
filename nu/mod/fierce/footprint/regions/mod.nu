use (path self ../../../../../../jab/nu/mod/target)
use (path self ../captures) [GAME]

# Each region where a pose's pictures differ cut out of both as PNGs
export def crops [out: path, pose: string, --pad: int = 16] {
    let c = (open ($out | path join $pose "pose.nuon"))
    if $c.pictures == null { error make { msg: $"($pose) was refused at capture: ($c.problems | str join '; ')" } }
    let crops = ($out | path join $pose "crops")
    if ($crops | path exists) { target retire $crops (target root ($GAME | path join .. ..)) }
    mkdir $crops
    let screen = {|label: string| $c.rows | where label == $label | first | get screen }
    for r in ($c.pictures.regions | enumerate) {
        let x0 = ([0 ($r.item.x0 - $pad)] | math max)
        let y0 = ([0 ($r.item.y0 - $pad)] | math max)
        let x1 = ([$c.pictures.width ($r.item.x1 + $pad)] | math min)
        let y1 = ([$c.pictures.height ($r.item.y1 + $pad)] | math min)
        let geometry = $"($x1 - $x0)x($y1 - $y0)+($x0)+($y0)"
        let png = ($crops | path join $"($r.index)_($x0)_($y0).png")
        let join = (if ($x1 - $x0) > ($y1 - $y0) { "-append" } else { "+append" })
        let made = (^magick "(" (do $screen picture) -crop $geometry +repage ")" "(" (do $screen picture_candidate) -crop $geometry +repage ")" $join $png | complete)
        if $made.exit_code != 0 { error make { msg: $"magick for region ($r.index): ($made.stderr)" } }
        print $"region ($r.index): ($r.item.pixels) pixels at most ($r.item.largest) apart in ($geometry), ($png)"
    }
}
