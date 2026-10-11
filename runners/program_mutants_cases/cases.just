# The program mutant runner's own cases (runners/program_mutants.nuon's
# `jf` over runners/program_mutants_cases/cases.nuon): nothing builds and
# nothing runs. A case's test prints its canned log from logs/ and exits
# with its status, 1 when the log holds nushell's error and 0 otherwise.

set shell := ["nu", "-c"]

cases := justfile_directory()

# An empty image where the runner looks for one.
cand-build dir:
    mkdir '{{dir}}/debug'; touch '{{dir}}/debug/fps.jab'

# The canned log of the case the output directory names, and its status.
image-test image out assets kernel *fixtures:
    let log = (open --raw ('{{cases}}' | path join logs $"('{{out}}' | path basename).log") | decode); print -n $log; exit (if ($log | str contains "Error: ") { 1 } else { 0 })

# A composed case's log: shapes.nu's failure for the case, its paths made
# relative to this repository.
compose case:
    let repo = ('{{cases}}' | path dirname | path dirname); let r = (^nu ('{{cases}}' | path join shapes.nu) '{{case}}' | complete); print -n ($r.stderr | str replace --all $"($repo)/" "" | str trim --right | $in + (char nl))
