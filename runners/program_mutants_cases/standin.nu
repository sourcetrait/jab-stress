# The survivor case's stand-in for a process no signal ends: a directory
# the checkout runner (runners/checkout_mutants.nuon) and its recovery
# (runners/checkout_restore.nuon) read as their `proc`, laid out beside the
# scratch checkout as `<checkout>.proc`. It holds a link to the host's own
# `<proc>/<host_pid>`, which the runner reads for the host's group, and
# nothing else until the survivor case's test writes an entry for
# STANDIN_PID carrying the run's mark. While STANDIN_PID exceeds the
# kernel's `pid_max`, no process or group can hold it, so the sweep's
# signals to the entry fail and it never goes; the limit is read before
# anything is laid out.
#
# Usage: nu standin.nu <checkout> <host_pid> <proc>
#
# <checkout> is a scratch checkout `checkout.nu` laid out, and
# `<checkout>.proc` must not exist. <host_pid> is the Grammar MCP host's
# pid, `$nu.pid` in a run body, and <proc> the proc filesystem.

# The stand-in's pid.
export const STANDIN_PID = 99999999

def main [checkout: path, host_pid: int, proc: path] {
    let dir = $"($checkout).proc"
    if ($dir | path type) != null { error make {msg: $"($dir) exists; a stand-in starts empty"} }
    let pid_max = (open --raw ($proc | path join "sys" "kernel" "pid_max") | decode | str trim | into int)
    if $STANDIN_PID <= $pid_max {
        let msg = $"the stand-in's pid ($STANDIN_PID) is within pid_max ($pid_max)"
        error make {msg: $"($msg), where a process could hold it"}
    }
    let host = ($proc | path join ($host_pid | into string))
    if ($host | path type) != "dir" { error make {msg: $"($host) is no process, so ($host_pid) is no host's pid"} }
    mkdir $dir
    ^ln -s $host ($dir | path join ($host_pid | into string))
    print $"stand-in: ($dir), pid ($STANDIN_PID) past pid_max ($pid_max), the host's ($host_pid) linked"
}
