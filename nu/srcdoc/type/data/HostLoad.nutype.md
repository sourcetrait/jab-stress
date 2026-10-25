# HostLoad.nutype

The shape of a line of a recorded step's `host_load.nuonl`, one reading of
the host's processes (`nu/mod/runner/hostload`'s reading): its kind, its
number in the step, its time since boot in seconds, the clock ticks a
second of its CPU and start times, the host's busy CPU ticks, why it
failed where it did, and every process by its pid, start, parent, name,
and CPU ticks. A landing holds each line to it (`runner record outputs`).
