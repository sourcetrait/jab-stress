# mod.nu

One target's qualification record from a bench run of the game's qualification
bench: every run with its standing, its identity, that identity's agreement
with the candidate and the target, and its conditions against its step; each
case of the matrix with its runs; every acceptance run's verdict; the controls'
and the diagnostics' readings; the bench's one host and one QEMU and each case's
one backend; the host; and its own ledger and verdicts. `main`
writes it as qualification.nuon and prints the record's own verdicts; the
check derives them again from the reopened inputs.

## def expected-of

The runs a step's words ask for, the gauge's defaults where they name
none: `run` its `--runs`, 3 unless given, each run n played at its n of
`--seeds`, else n; `play` one run at its `--seed`, else 1; `audio` one
run, unseeded. The verb is matrix's step-verb, in either word shape.

## def identity-summary

A run's identity as the record keeps it, from the identity run-request
resolved: its source, binding, and recorded SHA-256; the build's tree,
flags, and the image's, ELF's, and kernel's SHA-256; the assets; the
workspace's and the program's commits; the machine; the cap; the QEMU;
the toolchain; the host; the mode; and the capture's shim and nonce.

## def dir-of

A run's directory as its report's run-dirs find it, null where none is.

## def step-words

A step's words: the definition's at the candidate's commit, a packaged
run's as its package reads them, else the bench run's own.

## def step-role

A step's named build, read from the candidate's definition before its
words are resolved (matrix's role-of), null for the tree's own.

## def step-runs

A bench step's runs as the record keeps them (record-of): each run of
its gauge.nuon read through run-request, its standing and reasons as the
bench-doc classified it, its build, its identity (identity-summary) and
that identity's agreement with its build, the candidate, and the target
(build-of, agreement-of), its conditions against its step's words
(conditions-of), its backend, the window and the audio driver its run
record names, whether it was probed, its bundle, its measurement, its CPU
windows, and an audio run's reading.

## def condition-problems

The bench's one host and one QEMU, by each identity's hostname and its
QEMU's version and binary SHA-256, and each case's one backend: a bench
that ran on two hosts or two QEMUs, or a case holding two backends,
offscreen against a window or two audio drivers, mixes conditions no
verdict may pool, each named.

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
refusals. Admissible as the shim control finds.
Read once every expected run is there, valid, the candidate's, probed,
bundled, and read whole, each problem named once: a run the control's
rules or its missing bundle already name is not named again for the stage
that leaves it unread.

## def service-reading

The service active's reading (SceneOwnership on 1KB1): its runs passing
and run, every verdict judging the service besides the ceiling
(service-problems), and each run's window, whether its service started,
its offered count and rate a frame, its applied, dropped, and skipped,
its handoff, its apply phase's median and most, its oldest message's age
at the median, and the run's median frame.

## def refusal-reading

The feature unavailable's reading (1KA1): each run's start refused under
the floor (GFX_FLOOR), no window closed, no frame with the service
running, the run's conditions its step's, its median frame reported and
never judged; met once every expected run is there, valid, and its
build's (control-problems), with nothing else named.

## def audio-reading

The audio's reading (RegressionSuite's play as a bench step): each debug
run's reading, gauge/audio's, its counters, its QEMU log, and its
continuity where its sound was recorded, beside its standing, which is
diagnostic and never judged; met once every expected run is there, the
candidate's debug build with the audio's QEMU words, and its reading and
conditions name nothing; the runs on live sound, their continuity unread,
listed.

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

## def frozen-of

A packaged bench's freeze, from the manifest its preflight copied into the
run (`preflight/package.nuon`): the manifest held to the candidate, the
candidate file's SHA-256 it was made for, the image, the kernel, and the
asset tree's digest, and each named build's image and kernel, each
mismatch a problem of the bench; then the candidate holding the
manifest's ELFs, the exports', whose symbol tables carry RELEASE where the
candidate's tree builds' do not, the images' bytes the same, its own and
each named build's. A bench without the manifest keeps the candidate's
ELFs and says the freeze's is unknown.

## def readers-of

The readers' identity, jab-stress's and jab's checkouts and the nu that
runs them (jab's `identity reader`), taken as a command starts, just after
its code is read. A record names the code that read it: a check runs for
most of an hour, and a checkout that moves meanwhile would otherwise be
named in place of the one read.

## def record-of

One target's qualification record from a bench run (the file header):
`bench` the run's directory, `candidate` the candidate's record file,
`target` its named spec. A bench run from a host package (bench.nuon's
`package`) is held to the candidate's bench file as its package runs it
(packaged-bench at the package's directory), and its runs to the freeze
(frozen-of), the manifest kept under the bench's `package`; every bench's
definition is read with its words resolved where the run's builds lay
(resolved-in, bench.nuon's `build_root`), and each step's build from the
words before (step-role). An acceptance run's verdict judges its service
in the service active's case; a case whose steps the target holds none of
is not applicable, its reading null and its reason kept. Its ledger is matrix's
ledger-of over the record, the tag's state, and the bench's and the
conditions' problems; its verdicts verdicts-of's. Its `readers` the
identity `--readers` gives, else readers-of's taken as it starts.

## def main

A target's record (record-of), the readers' identity taken first
(readers-of), written as qualification.nuon in `out`, the record's own
verdicts printed after it.
