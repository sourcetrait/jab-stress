# mod.nu

The cadence lane's summary: every run of each cadence pooled, per cadence and
leg, from the gauge.nuon files a battery wrote under one base directory, each
run under the cadence its own identity asked, read through `gauge identity
request`, never the report's summary unless that is the identity's fallback;
distributions by nearest rank, untrimmed. Its bin: `nu/bin/nuance/fierce/lane.nu
<base> <out.nuon> <label>...`; or `use` the module and call `analyse`.

## const CEILING

the ceiling in microseconds, judged on the critical path's median; the
frames at or over it are the tail

## def spread

Least, median, 95th, 99th, and greatest by nearest rank, null-free.

## def started

Each row with the interval from the presented flip before it to its
own, both read at the call's start, null for one not presented, and
with whether the frame before it ran past the period.
