# A step's verb on the parity's bin: parity its main, fault its fault
def verb-of [recipe: string]: nothing -> list<string> {
    match $recipe {
        "parity" => []
        "fault" => [fault]
        _ => (error make { msg: $"no parity step ($recipe)" })
    }
}

# The parity's base new, the base made
export def ready [a: record]: nothing -> record {
    if ($a.base | path exists) { error make { msg: $"($a.base) exists; a parity is written once" } }
    mkdir $a.base
    {}
}

# Each step's parity or fault by the parity's bin, its verdict read back
export def main [a: record]: nothing -> record {
    let results = ($a.steps | each {|s|
        let out = ($a.base | path join $s.name)
        let r = (^$nu.current-exe $a.nuance ...(verb-of $s.recipe) $a.kernel $s.image $out ...$s.flags | complete)
        ($r.stdout + $r.stderr) | save --raw -f ($a.base | path join $"($s.name).log")
        let v = ($out | path join "verdict.nuon")
        if ($v | path exists) { let x = (open $v); { name: $s.name, exit: $r.exit_code, ok: $x.ok, judged: $x.judged, failed: $x.failed } } else { { name: $s.name, exit: $r.exit_code, ok: false, judged: 0, failed: -1 } }
    })
    { ok: ($results | all {|x| $x.ok }), steps: $results }
}
