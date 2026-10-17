# JointTiming's selector (TimingSelector): the decision over one readings
# record, and the selector's own fixtures, the script given so a
# mutant's copy runs in its place.

set shell := ["nu", "-c"]

timing := justfile_directory() / "../timing"

select readings out:
    nu {{timing}}/select.nu {{readings}} {{out}}

select-holds script scratch:
    nu {{script}} holds {{scratch}}

select-sample readings:
    nu {{timing}}/select.nu sample {{readings}}

select-mutants set scratch:
    nu {{timing}}/mutants.nu {{set}} {{scratch}}
