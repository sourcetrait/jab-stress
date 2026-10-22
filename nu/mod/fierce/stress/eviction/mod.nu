use (path self ./cycle)
use (path self ./held)
use (path self ./reuse)
use (path self ../../places)

# The eviction fixtures named, every one by default, each result kept
export def main [kernel: path, image: path, disk: path, out: path, ...fixtures: string]: nothing -> nothing {
    let asked = (if ($fixtures | is-empty) { ["cycle" "rebuild" "held" "reuse"] } else { $fixtures })
    mkdir $out
    for f in $asked {
        let s = (date now)
        let result = (match $f {
            "cycle" => (cycle eviction-cycle $kernel $image $disk $out)
            "rebuild" => (cycle rebuild-bound $kernel $image $disk $out)
            "held" => (held held-partial $kernel $image $disk $out)
            "reuse" => (reuse slot-reuse $kernel $image $disk $out)
            _ => (error make { msg: $"no fixture ($f)" })
        })
        let took = (((date now) - $s) / 1sec | math round --precision 1)
        { fixture: $f, seconds: $took, result: $result } | to nuon --indent 1 | save -f ($out | path join $"($f).nuon")
        print $"eviction ($f): ok in ($took) s"
    }
}

# The fixtures on jab's debug tree, or another image beside its kernel and disk
export def on-debug [out: path, ...fixtures: string, --image: string = ""]: nothing -> nothing {
    let p = (places)
    main $p.kernel (if $image == "" { $p.image } else { $image }) $p.disk $out ...$fixtures
}
