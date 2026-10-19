use (path self ../gauge)

# A battery's selections on `harts`: the base on three, auto, each forced count
def selections [a: record, harts: int]: nothing -> list<record> {
    let base = (if $harts == 3 { [{ label: "base62", image: $a.base62, workers: -1, grain: 32 }] } else { [] })
    let auto = [{ label: "auto", image: $a.new, workers: -1, grain: 32 }]
    let forced = (0..<$harts | each {|w| { label: $"w($w)", image: $a.new, workers: $w, grain: 32 } })
    let first = ($base ++ $auto ++ $forced | each {|s| $s | update label $"($s.label)_1" })
    $first ++ ($first | reverse | each {|s| $s | update label ($s.label | str replace '_1' '_2') })
}

# The batteries by harts and route, each with its batches
def plan [a: record]: nothing -> list<record> {
    let names = { "3": "three", "4": "four", "8": "eight" }
    [3 4 8] | each {|h| [{ route: $a.settled, kind: "settled" } { route: "", kind: "factory" }] | each {|r|
        let name = $"($names | get ($h | into string))_($r.kind)"
        { name: $name, base: ($a.gauge | path join $name), harts: $h, route: $r.route, batches: (selections $a $h) }
    } } | flatten
}

# Every battery's base new and its images present; the batteries the check reads
export def ready [a: record]: nothing -> record {
    let batteries = (plan $a)
    let taken = ($batteries | where {|b| $b.base | path exists })
    if ($taken | is-not-empty) { error make { msg: $"battery bases exist: ($taken | get base | str join ', ')" } }
    let missing = ($batteries | get batches | flatten | where {|b| $b.image != "" and not ($b.image | path exists) } | get image | uniq)
    if ($missing | is-not-empty) { error make { msg: $"image missing: ($missing | str join ', ')" } }
    { batteries: ($batteries | each {|b| { name: $b.name, base: $b.base, batches: ($b.batches | length) } }) }
}

# Each battery's selections measured with their CPU, then compared by field
export def main [a: record]: nothing -> record {
    mut results = []
    for bat in (plan $a) {
        mkdir $bat.base
        for b in $bat.batches {
            let image = (if $b.image == "" { [] } else { [--image $b.image] })
            let route = (if $bat.route == "" { [] } else { [--route $bat.route] })
            let selection = (if $b.workers < 0 { [] } else { [--workers ($b.workers | into string) --grain ($b.grain | into string)] })
            gauge batch $a.fps $bat.base $b.label release 3 ([--cadence "1" --harts ($bat.harts | into string)] ++ $selection ++ [--cpu] ++ $image ++ $route) --name $bat.name
        }
        let files = ($bat.batches | each {|b| $bat.base | path join $b.label "gauge.nuon" })
        let compares = (if $bat.harts != 3 {
            [critical_us raster_us] | each {|f| gauge compare $a.fps $files $f $bat.base --diagnostic }
        } else {
            [critical_us raster_us] | each {|f| gauge compare $a.fps $files $f $bat.base }
        })
        $results = ($results | append { name: $bat.name, batches: ($bat.batches | length), compares: $compares })
    }
    { batteries: $results }
}
