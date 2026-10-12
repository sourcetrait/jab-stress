# The program mutant runner's composed cases: each raises the failure its
# case stands for, so that the case's canned log is nushell's own
# rendering of that failure.
#
# Usage: nu shapes.nu <case>
use std/assert

const LABEL = "the eviction cycle"
const HOLD_EXPIRED = "fps: held job never released"
const CENSUS = "the census reader"

# A bay return's counts, the accounting assertion's inputs.
def phase []: nothing -> record {
    {leg: "bay_return", renewed: 459, free: 240, built: 476, evicted: 236, first_miss: 264}
}

# A field the run's record lacks, read where no assertion stands.
def unrelated-unexercised [] {
    let run = {status: 16, serial: $HOLD_EXPIRED}
    let held = $run.unexercised
    $held
}

# Another assertion, its title saying unexercised.
def other-assert-unexercised [] {
    let said = ["fps: tile pool on"]
    assert ($said | any {|l| $l | str contains "fps: worker held" }) $"($LABEL): unexercised, the worker was never held"
}

# The accounting's words raised between two assertions.
def neighbour-expect [] {
    let p = (phase)
    assert ($p.renewed > 0) $"($LABEL): the ($p.leg) phase renewed keys"
    if $p.built != $p.renewed { error make {msg: $"($LABEL): the ($p.leg) phase built its ($p.renewed) renewed keys and evicted those past its ($p.free) free slots, built ($p.built), evicted ($p.evicted)"} }
    assert ($p.first_miss != null) $"($LABEL): the ($p.leg) phase drew blocks without their tiles"
}

# The watchdog's words raised between two assertions.
def neighbour-unexercised [] {
    let said = [$HOLD_EXPIRED]
    assert ($said | is-not-empty) $"($LABEL): the run printed its lines"
    if $HOLD_EXPIRED in $said { error make {msg: $"($LABEL): unexercised, the hold expired unreleased, exit 16: `($HOLD_EXPIRED)`, status 16"} }
    assert equal ($said | length) 1 $"($LABEL): the run printed one line"
}

# The renewed counts held by a helper raising at its argument's span.
def renewed-held [p: record] {
    if $p.built == $p.renewed { return true }
    error make {
        msg: $"($LABEL): the ($p.leg) phase built its ($p.renewed) renewed keys and evicted those past its ($p.free) free slots, built ($p.built), evicted ($p.evicted)"
        label: {text: "these counts", span: (metadata $p).span}
    }
}

# An exception raised while an assertion's argument evaluates.
def argument-exception [] {
    let p = (phase)
    assert (renewed-held $p) $"($LABEL): the ($p.leg) phase built its renewed keys"
    assert ($p.first_miss != null) $"($LABEL): the ($p.leg) phase drew blocks without their tiles"
}

# An assertion inline after a block's opening brace.
def inline-assert [] {
    let p = (phase)
    if $p.renewed > 0 { assert ($p.built == $p.renewed) $"($LABEL): the ($p.leg) phase built its ($p.renewed) renewed keys and evicted those past its ($p.free) free slots, built ($p.built)" }
}

# The census's expect, its reason absent from the title.
def reason-absent [] {
    let refused = [12]
    assert ($refused | is-empty) $"($CENSUS): every census frame whole and accounting, chunk ($refused.0) refused"
}

# The census's expect beside another reason.
def reason-wrong [] {
    let refused = [12]
    assert ($refused | is-empty) $"($CENSUS): every census frame whole and accounting, chunk ($refused.0): an item that is no surface:count pair"
}

# The census's reason in the assertion's source alone.
def reason-excerpt [] {
    let why = "does not reassemble"
    assert ($why != "does not reassemble") $"($CENSUS): every census frame whole and accounting, chunk 12 refused"
}

# The census's reason in the title, across its wrap.
def reason-wrapped [] {
    let refused = [12]
    assert ($refused | is-empty) $"($CENSUS): every census frame whole and accounting, chunk ($refused.0) does not reassemble"
}

# A refusal's text across two lines, as a record's reader gives it.
const REFUSAL = "refused: the slot's record does not hold for its tile:\n  generation: 3"

# `assert equal` with its left value across lines, so its label hangs
# from `-| and runs across them too.
def equal-left-multiline [] {
    assert equal $REFUSAL null $"($LABEL): a reused slot's record reads as no refusal: ($REFUSAL | to nuon)"
}

# The same of its right value.
def equal-right-multiline [] {
    assert equal null $REFUSAL $"($LABEL): a reused slot's record reads as the refusal expected"
}

def main [case: string] {
    match $case {
        "unrelated_unexercised" => { unrelated-unexercised }
        "other_assert_unexercised" => { other-assert-unexercised }
        "neighbour_expect" => { neighbour-expect }
        "neighbour_unexercised" => { neighbour-unexercised }
        "argument_exception" => { argument-exception }
        "inline_assert" => { inline-assert }
        "reason_absent" => { reason-absent }
        "reason_wrong" => { reason-wrong }
        "reason_excerpt" => { reason-excerpt }
        "reason_wrapped" => { reason-wrapped }
        "equal_left_multiline" => { equal-left-multiline }
        "equal_right_multiline" => { equal-right-multiline }
        _ => { error make {msg: $"no case named ($case)"} }
    }
}
