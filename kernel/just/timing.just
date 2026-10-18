# JointTiming's selector (TimingSelector). `select` writes the decision
# over one readings record.

set shell := ["nu", "-c"]

timing := justfile_directory() / "../timing"

select readings out:
    nu {{timing}}/select.nu {{readings}} {{out}}
