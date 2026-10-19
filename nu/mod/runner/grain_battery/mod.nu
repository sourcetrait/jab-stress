use (path self ../gauge)

# The heights' order, each batch's partner of the other height beside it
const ORDER = [16 32 32 16 16 32 32 16]

# The batches in their order and the batteries by harts and route
def plan [a: record]: nothing -> record {
    let batches = ($ORDER | enumerate | each {|o|
        let nth = ($ORDER | first ($o.index + 1) | where {|g| $g == $o.item } | length)
        { label: $"g($o.item)_($nth)", workers: 3, grain: $o.item }
    })
    let names = { "4": "four", "8": "eight" }
    let batteries = ([4 8] | each {|h| [{ route: $a.settled, kind: "settled" } { route: "", kind: "factory" }] | each {|r|
        let name = $"($names | get ($h | into string))_($r.kind)"
        { name: $name, base: ($a.gauge | path join $name), harts: $h, route: $r.route }
    } } | flatten)
    { batches: $batches, batteries: $batteries }
}

# Every battery's base new and the image present; the batteries the check reads
export def ready [a: record]: nothing -> record {
    let p = (plan $a)
    let taken = ($p.batteries | where {|b| $b.base | path exists })
    if ($taken | is-not-empty) { error make { msg: $"battery bases exist: ($taken | get base | str join ', ')" } }
    if not ($a.image | path exists) { error make { msg: $"image missing: ($a.image)" } }
    { batteries: ($p.batteries | each {|b| { name: $b.name, base: $b.base, batches: ($p.batches | length) } }) }
}

# Forced W 3 at 16 and 32 rows on four and eight harts, each battery compared
export def main [a: record]: nothing -> record {
    let p = (plan $a)
    mut results = []
    for bat in $p.batteries {
        mkdir $bat.base
        for b in $p.batches {
            let route = (if $bat.route == "" { [] } else { [--route $bat.route] })
            gauge batch $a.fps $bat.base $b.label release 3 ([--cadence "1" --harts ($bat.harts | into string) --workers ($b.workers | into string) --grain ($b.grain | into string) --image $a.image] ++ $route) --name $bat.name
        }
        let files = ($p.batches | each {|b| $bat.base | path join $b.label "gauge.nuon" })
        let compares = ([critical_us raster_us] | each {|f| gauge compare $a.fps $files $f $bat.base --diagnostic })
        $results = ($results | append { name: $bat.name, batches: ($p.batches | length), compares: $compares })
    }
    { batteries: $results }
}
