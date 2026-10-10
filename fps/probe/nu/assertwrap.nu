use std/assert

def main [how: string] {
    let check = {|x: int| assert ($x < 2) $"the value ($x) under 2" }
    match $how {
        "each" => { [1 2 3] | each {|x| assert ($x < 2) $"the value ($x) under 2"; $x } | ignore }
        "for" => { for x in [1 2 3] { assert ($x < 2) $"the value ($x) under 2" } }
        "do" => { do $check 3 }
        "do-in-for" => { for x in [1 2 3] { do $check $x } }
        "par-each" => { [1 2 3] | par-each {|x| assert ($x < 2) $"the value ($x) under 2"; $x } | ignore }
        _ => { print "each | for | do | do-in-for | par-each" }
    }
}
