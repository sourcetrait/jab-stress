# mod.nu

The host's CPU by process through a recorded step (HostLoad): readings into
the step's `host_load.nuonl`, a baseline as the step starts, one every
INTERVAL, and one as it ends, each line a reading held at landing to
`nu/type/data/HostLoad.nutype`; then the step's summary of them in its
`step.nuon`. Linux alone: elsewhere every reading fails and says so. A
reading sees the processes of its own process namespace, so on the box, a
container, the host's other processes are seen only as unattributed CPU.

## const PROC

Linux's process filesystem, which every reading reads and never writes.

## const INTERVAL

Ten seconds between a step's readings, the sampler's own wait.

## const NAMED_CORES

0.1 cores: a foreign or unknown process reaching it over an interval is
named in the step's summary.

## const FINAL_WAIT

How long a step's end waits for the sampler's final reading before the
summary says the final reading was not written.

## def clock-ticks

The clock ticks a second of the process table's times, `getconf CLK_TCK`,
which every reading carries as `ticks`.

## def root

The step's process tree's root: this process, the runner, by its pid and
its start in clock ticks since boot, a process's identity as the
launcher's table takes it (jab's `shim/crates/pipe/src/table.rs`). The step's
bin is its child, so the step's processes are its descendants.

## def reading

One reading: `at`, seconds since boot from the process filesystem's
`uptime`, the clock every process's start is counted on; `busy`, the host's
busy CPU ticks over every CPU from its `stat`, user, nice, system, irq,
softirq, and steal; and every process of the table by its pid, start,
parent, name, and CPU ticks, user and system, from its own `stat` (a
process gone between the listing and its read is left out). Never a
process's command line, environment, user, or paths (PublicRecords), and
its name stays under the Scrub rules like any field a public project lands.
A reading whose time or listing cannot be read says `failed`, its reason,
with no processes, and stays in the file as such.

## def append-reading

A reading written to the step's file as one NUON line.

## def sample

The readings after the baseline, one each INTERVAL, the sampler a job of
its own beside the step's command; told to stop, it takes one more
reading, the final partial interval, then answers the main thread.

## def stop

The sampler told to stop and its answer awaited, true when its final
reading was written within FINAL_WAIT. The step's end calls it whatever
the step did, a raised error's path too.

## def summary

What a step's readings show, its claim no more than that: `readings`, the
lines; `covered`, the first and last good reading's time; `final`, whether
the final reading was written; `gaps`, each failed reading; `unbounded`,
each process seen without a first bound, absent from the reading before it
and started before that reading, its CPU in that interval unattributed;
`named`, every foreign or unknown process (classes-of) whose rate over an
interval reached NAMED_CORES, its interval and cores; and `unattributed`,
each interval's busy CPU less the CPU attributed to the processes read, in
cores, which holds the host's processes outside the step's namespace, the
tails of processes that exited between readings, and any process born and
reaped between them, which no reading sees. A process's rate is its CPU
between two readings of it over their interval, a process born after a
reading bounded by its start and no CPU, one alive at the baseline
measured from the baseline, never by its lifetime's average; the final
partial interval counts, so a short step still has its coverage. No
record says the host was free of interference: the summary names what the
covered readings saw reach the bound.

## def classes-of

Each reading's processes classed by the reading's number: `step`, a
descendant of the root; `foreign`, a process whose chain of parents reaches
the top of the table through living parents and never the root; `unknown`,
a chain broken by a vanished parent or a parent started after its child, or
a process reparented since it was first seen. A class found while the
parents lived is kept for the process's life; unknown is never foreign.

## def class-of

One process's class by its chain of parents in one reading, a class
established earlier standing for its process.

## def busy-ticks

The host's busy CPU ticks from the first line of the process filesystem's
`stat`, every CPU summed.

## def process-of

A process's pid, start, parent, name, and CPU ticks from its `stat`, the
name between the first parenthesis and the last, null when the process is
gone or its `stat` is unreadable.
