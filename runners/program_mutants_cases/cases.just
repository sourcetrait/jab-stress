# The mutant runners' own cases (the `jf` of runners/program_mutants.nuon
# and runners/program_mutants_reasons.nuon over
# runners/program_mutants_cases/cases.nuon): nothing builds and nothing
# runs. A case's test prints its canned log from logs/ and exits with its
# status, 1 when the log holds nushell's error and 0 otherwise; `check`
# holds a run to those logs and statuses. `checkout` lays out the scratch
# checkout the checkout runner (runners/checkout_mutants.nuon) reads them
# from.

set shell := ["nu", "-c"]

cases := justfile_directory()

# An empty image where the runner looks for one.
cand-build dir:
    mkdir '{{dir}}/debug'; touch '{{dir}}/debug/fps.jab'

# The canned log of the case the output directory names, and its status.
image-test image out assets kernel *fixtures:
    let log = (open --raw ('{{cases}}' | path join logs $"('{{out}}' | path basename).log") | decode); print -n $log; exit (if ($log | str contains "Error: ") { 1 } else { 0 })

# A consumer's run of the cases held to the canned logs and statuses:
# `logs` the run's logs directory, `results` its results as NUON.
check logs results:
    nu '{{cases}}/check.nu' '{{logs}}' '{{results}}'

# The checkout runner's scratch checkout at `dir`, which must not exist:
# its `case` file, its justfile, and the cases as its set.nuon.
checkout dir:
    nu '{{cases}}/checkout.nu' '{{dir}}'

# A composed case's log: shapes.nu's failure for the case, its paths made
# relative to this repository.
compose case:
    let repo = ('{{cases}}' | path dirname | path dirname); let r = (^nu ('{{cases}}' | path join shapes.nu) '{{case}}' | complete); print -n ($r.stderr | str replace --all $"($repo)/" "" | str trim --right | $in + (char nl))
