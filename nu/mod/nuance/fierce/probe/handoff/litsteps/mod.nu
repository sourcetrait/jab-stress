# Each pair of pixels' greatest channel difference
def apart-ints [ia: list<int>, ib: list<int>]: nothing -> list<int> {
    $ia | zip $ib | each {|c|
        let u = $c.0
        let v = $c.1
        if $u == $v { 0 } else {
            let r = (($u bit-and 255) - ($v bit-and 255))
            let g = ((($u bit-shr 8) bit-and 255) - (($v bit-shr 8) bit-and 255))
            let b = (($u bit-shr 16) - ($v bit-shr 16))
            let r = (if $r < 0 { 0 - $r } else { $r })
            let g = (if $g < 0 { 0 - $g } else { $g })
            let b = (if $b < 0 { 0 - $b } else { $b })
            if $r > $g { if $r > $b { $r } else { $b } } else { if $g > $b { $g } else { $b } }
        }
    }
}

# The most a capture steps between neighbours along a rectangle's rows
export def main [capture: path, rect: string, crosshair: int]: nothing -> nothing {
    let r = ($rect | from nuon)
    let bytes = (open --raw $capture | into binary)
    let head = (($bytes | bytes index-of --all 0x[0a] | get 2) + 1)
    let ch = $crosshair
    let s = (date now)
    let found = ($r.1..<$r.3 | each {|y|
        let runs = (if (($y - 540) | math abs) <= $ch { [[$r.0, (960 - $ch)], [(961 + $ch), $r.2]] } else { [[$r.0, $r.2]] })
        $runs | where {|run| ($run.1 - $run.0) >= 2 } | each {|run|
            let from = ($head + ((($y * 1920) + $run.0) * 3))
            let ints = ($bytes | bytes at $from..<($from + (($run.1 - $run.0) * 3)) | chunks 3 | into int --endian little)
            let steps = (apart-ints ($ints | drop 1) ($ints | skip 1))
            let most = ($steps | math max)
            { y: $y, x: ($run.0 + ($steps | enumerate | where item == $most | get 0.index)), most: $most, over4: ($steps | where {|d| $d > 4 } | length) }
        }
    } | flatten)
    let worst = ($found | sort-by most | last)
    print ({ most: $worst.most, x: $worst.x, y: $worst.y, rows: ($found | get y | uniq | length), steps_over_4: ($found | get over4 | math sum), ms: (((date now) - $s) / 1ms | into int) } | to nuon)
}
