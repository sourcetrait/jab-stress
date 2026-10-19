# JointTiming's selector (TimingSelector), a shim over its bin until
# JustRetired. `select` writes the decision over one readings record.

set shell := ["nu", "-c"]

timing := justfile_directory() / "../../nu/bin/nuance/kernel/timing.nu"

select readings out:
    nu {{timing}} {{readings}} {{out}}
