# mod.nu

One target's qualification record from a bench run of the game's qualification
bench: every run with its standing, its identity, and that identity's agreement
with the candidate and the target; each case of the matrix with its runs; every
acceptance run's verdict; the controls' and the diagnostics' readings; the host;
and the limits. `main` writes it as qualification.nuon and prints the count of
problems its check names.

## def flag-of

The value after a flag among a step's words, null where it is absent.

## def expected-of

The runs a step's words ask for, the gauge's defaults where they name
none: `run` its `--runs`, 3 unless given, each run n played at its n of
`--seeds`, else n; `play` one run at its `--seed`, else 1.

## def identity-summary

A run's identity as the record keeps it, from the identity run-request
resolved: its source, binding, and recorded SHA-256; the build's tree,
flags, and the image's, ELF's, and kernel's SHA-256; the assets; the
workspace's and the program's commits; the machine; the cap; the QEMU;
the toolchain; the host; the mode; and the capture's shim and nonce.

## def dir-of

A run's directory as its report's run-dirs find it, null where none is.

## def step-runs

A bench step's runs as the record keeps them (record-of): each run of
its gauge.nuon read through run-request, its standing and reasons as the
bench-doc classified it, its identity (identity-summary) and that
identity's agreement with the candidate and the target (agreement-of),
whether it was probed, its bundle, its measurement, and its CPU windows.

## def bench-problems

The bench run against the candidate's bench file: every step of the
file run, each with the file's own words, none it does not hold, and
each done; every disagreement named.

## def expected-runs

A case's expected runs: every step's runs as its words ask them, the
bench run's words where the step ran and the candidate's bench file's
where it did not; each found among the runs or missing, and a found run
played at another seed than its step asks named.

## def control-problems

Why a control's runs leave it unmet, each named: an expected run
missing, a run not valid, and a run whose identity is not the
candidate's on the target (agreement-of).

## def shim-reading

The shim control's reading (ProbeRuns' observer protocol): its probed
arm the runs whose identity names the shim, its plain arm the others,
each run valid and the candidate's; the shim's effect on every measure
over those runs (observer.nu); met once every expected run is there,
valid, and the candidate's (control-problems), admissible once every
effect is within its noise.

## def scaling-reading

The worker scaling control's reading: its forced arm the runs whose
identity asks a count of workers, its automatic arm the others; per leg
each run's critical path's and raster's medians, and each hart's
utilization over each run's whole window; the forced runs judged by
nothing but this comparison. Met once every expected run is there,
valid, and the candidate's (control-problems), with its CPU windows
read, each problem named.

## def presentation-reading

The presentation's reading from the probed runs, ProbeRuns' reader joined
by each run's directory (`proberuns analyse-runs`): each run's bundle;
each run's reading, its capture, bundle, flips, and pairing in turn, with
its shown, superseded, and repeated frames pooled whole and per leg; the
pools per cadence; the runs left unread, each at its stage with its
refusals; and the pairing's limits. Admissible as the shim control finds.
Read once every expected run is there, valid, the candidate's, probed,
bundled, and read whole, each problem named once: a run the control's
rules or its missing bundle already name is not named again for the stage
that leaves it unread.

## def diagnostic-reading

A diagnostic's readings from the normal play runs (DIAGNOSTICS): per
route run each leg it names, every leg the run holds where it names
none, with the fields it reads, and a leg a run lacks named missing.

## def ram-of

The program's RAM window at the candidate's commit, jab.inc's
JAB_PROGRAM_SIZE, beside the target's installed RAM (RamTopology): what
a report states on every target, the RAM past the window held apart.

## def watch-of

The watch's record of a bench run, `nu/bin/nuance.nu watch bench`'s
watch.nuon in its directory, null where the bench ran unwatched.

## def record-of

One target's qualification record from a bench run (the file header):
`bench` the run's directory, `candidate` the candidate's record file,
`target` its named spec.

## def main

A target's record (record-of), written as qualification.nuon in `out`,
its check's problems printed after it.
