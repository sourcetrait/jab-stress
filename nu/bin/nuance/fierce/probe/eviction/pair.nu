#!/usr/bin/env nu
# The pair module's path, bound at parse time
const PAIR = path self ../../../../../mod/nuance/fierce/probe/eviction/pair
use $PAIR

# A pair run's dumps read against a views run's key sets, printed as NUON
def main [pair: path, sets: path, a: int = 0, b: int = 4] {
    pair $pair $sets $a $b
}
