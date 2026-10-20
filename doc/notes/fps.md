# The fierce workbench

The workbench holds readers, probes, and stress fixtures for testing Jab's
fierce, the fps game at `kit/fierce`, beyond its own suite. Nothing in it is
generated. A run's record, its logs and results, is kept in the data
checkout beside this repository, `../jab-stress-data`, under `runs/`.
Builds, captures, and candidate trees are written outside both
repositories, under the session's scratch directory or
`$XDGX_TMP_HOME/jab-stress/`.

## Layout

- The readers of the gauge's batteries and captures are modules under
  `nu/mod/fierce/`, each run by its own bin under `nu/bin/nuance/fierce/`:
  `admission`, `poolgauge`, `packetgauge`, `workergauge`, `gaincurves`,
  `grainpairs`, `lane`, `tilecensus` with its resolver
  `tilecensus/resolve`, `identity_corrections`, `workerparity`,
  `footprint`, `qualification` with the shim control's rule `observer`,
  and `freeze`, which exports a commit's image with its provenance, the
  game's by default and walk's with `--program example/walk` (the
  kernel's walk export, [Kernel candidates](candidates.md)). Run one as
  `nu nu/bin/nuance/fierce/<reader>.nu ...`.
  - `poolgauge`, `packetgauge`, and `workergauge` take a mode, a base, an
    out, and the batches' labels; `admission`, `lane`, and `tilecensus` a
    base, an out, and the labels.
  - `gaincurves.nu <mode> <base> <out> <labels>` reads a battery's gain
    curves, and `gaincurves.nu table <reading> <builds>` prints a
    reading's builds as a markdown table. `grainpairs.nu` reads a
    battery's two band heights as matched pairs.
  - `workerparity.nu <kernel> <image> <out> [flags]` runs the parity,
    `fault` its faults, and `judge <out>` judges a parity again from its
    recorded launches.
  - `freeze.nu <repo> <commit> <cands> <expected> [--set <symbols>]
    [--program <dir>] [--debug]` exports a commit's program and builds it
    release, or debug with `--debug`, the export named after its symbols
    (`export_<commit>-footprint`, `export_<commit>-debug`).
  - `footprint.nu` runs FootprintEstimate's level comparison. `images
    <export>` builds eight debug images of one export, each in a copy of
    the export's program named `<export>_<label>`: for a view, `picture`
    and `picture_candidate` (debug, and debug with FOOTPRINT) for the
    pictures, `owner`, and `levels` and `levels_candidate` (debug with
    LEVELS, and with LEVELS and FOOTPRINT); for the clamp pose,
    `owner_clamp`, `levels_clamp`, and `levels_candidate_clamp`, the
    same with IZ_TEST. Each image keeps the kernel built with it as
    `kernel.elf`, its provenance, and the IZ_MIN its ELF was assembled
    with; their record is `footprint_images.nuon` in the export.
    `capture <export> <poses> <out> [--only <poses>]` launches each pose's
    kind's images, every pose `--only` names, comma separated, all of
    them by default, asks each launch for its frames' snapshots, and runs
    the footprint crate's `reference` and `differ` over the bound
    captures; a pose already captured into `out` is refused. `clamp-plan
    <dir> <surface>` plans the clamp pose's threshold and witnesses over a
    pose captured at the release floor. `read <out> <poses>` judges the
    pose set whole, and `crops <out> <pose>` cuts each region where a
    view's two pictures differ out of both, side by side. `reread <tree>
    <out>` reads a landed run again from its restoration, through `runner
    reread` with the reader `fps footprint`: each still copy made again
    and held file by file to the run's inventory, and remade as a checkout
    compiled it before jab c804ccb where it differs only outside the
    files the reference reads; each launch bound again and its UART read;
    the reference made anew; the reading made again beside the first, its
    record `again.nuon`.
  - `qualification.nu`: `candidate <out> [--tag <tag>]` builds jab's
    release tree and writes the candidate's record, jab's checkout clean
    and the tag, when given, on its HEAD, this repository's changes and
    tag recorded, each named build the bench files declare, the service
    build and the debug build, made first and recorded by name;
    `record <bench> <candidate> <target> <out>` writes a
    target's `qualification.nuon` from a bench run of
    `kit/fierce/bench/qual_<target>.nuon`, its own ledger and verdicts
    in it; `check <record> [--bench <dir>] [--inventory <file>]
    [--candidate <file>] [--out <dir>]` derives the record again from the
    bench's kept inputs, each step's report made again by jab's `gauge
    read batch`, a probed run whose bench kept no bundle bundled again in
    its work by jab's bundler, every reopened input held to the inventory,
    and writes
    the derived record and `check.nuon`, printing the record's differing
    stored answers, every problem, the preparation subset's verdict, and
    the final one, failing on a problem; `report <checks> <out.md>` writes
    the report from checks, `--compared <file>` rendering a `nuance.nu
    gauge compare` output as the comparison with the first baseline;
    `package <candidate> <export> <target> <out> [--exports <record>]`
    writes the candidate's host package for a target, one tar a host runs
    with `./do bench kit/fierce/qual_<target> --package <dir>`, each named
    build from its own export, `--exports` a NUON record such as
    `{service: <export>, debug: <export>}`, laid at `build/<name>`;
    `disks <bench> <inventory>
    <out>` makes a restored bench's disk copies again from today's content,
    each step's asset tree held to the digest its runs' identities record,
    rooted as the bench's checkout compiled it where it differs, and each
    disk to its inventory row, writing `disks.nuon`. Its module splits into
    `matrix`, the targets, the cases, the diagnostics, the other
    obligations, the packaged bench, the limits, the acceptance's and the
    conditions' rules, the ledger, and the helpers the others share, then
    `candidate`, `record`, `check`, `report`, `package`, and `disks`.
    `tilesources` holds how a tree compiled before jab c804ccb named its
    tiles' sources, for `disks` and footprint's reread alike.
- The probes are modules under `nu/mod/nuance/fierce/probe/`, one a
  probe, each run by its own bin under `nu/bin/nuance/fierce/probe/`:
  - `eviction.nu` runs the tile eviction probe: views' key sets at first
    sight, and two views alternated under a slot cap with a dump at every
    settle. `on-debug <mode> <out> [slots] [--image <image>]` runs it on
    jab's debug tree or another image, `on-debug pair <out> <slots>
    --image <image> [--view] [--cycles] [--modes] [--tag]` the pair run.
    Its `building` mode dumps a settle in pairs, one dump of the finished
    tiles and one asking for the tile in construction too. Its `quota`
    mode runs the work quota's cases under the lift: whole tiles to the
    settle, then one construction a phase under ONCE, each held for a
    dump of the tile in construction. `eviction/rows.nu <api>` reads the
    pool's counters a frame, and `eviction/pair.nu <pair> <sets> [a] [b]`
    a pair run's reading against the views' key sets.
  - `hold.nu on-debug <out> [--image] [--name] [--no-hold]` runs the
    join's hold.
  - `handoff.nu holds <out>`, `builder <out>`, and `builder-on <image>
    <out>` run jab's handoff and builder fixtures alone on the debug tree.
    `handoff/oblique.nu on-debug <spec> <disk> <out>` and
    `handoff/identity.nu on-debug <base> <handoff disk> <still disk>
    <out>` run the handoff probes; `handoff/rows.nu`, `handoff/due.nu`,
    and `handoff/litsteps.nu` read a capture's counters, the launch's due
    order, and the lit loop's steps.
  - `layout.nu <cands> <commit> <names>` lays out the tile layout
    candidates from a commit; `knobs.nu <mode> <out>` probes the pool's
    knobs on the debug build.
- `nu/bin/nuance/fierce/pose.nu <map> <image> <poses> <out> <kernel>
  [set]` captures a map's poses on an image.
- `nu/bin/nuance.nu` holds the light verbs: `build <dir> --set <symbols>`
  and `test <dir> --set <symbols>` through jab's driver, `check <file>
  [--ide]`, `hot <elf>`, `fierce tiles keys|lit-steps|handoff` through
  jab's tiles bin (`keys` reads a capture's tile dumps as each tile's
  header and the SHA-256 of its texels), and `fierce census reader-holds
  <tree> <serial>` and `gauge-load`.
- The development smoke is fierce's own, `kit/fierce/nu/bin/nuance.nu
  smoke <seeds> <seconds>` in the Jab checkout.
- `nu/mod/fierce/stress/` holds the release tier's fixtures, the
  exhaustive tests a manual release build runs beside jab's own suite,
  each asserting and run on a debug image, each run by its bin under
  `nu/bin/nuance/fierce/stress/`. `eviction` holds the tile eviction
  fixtures: `cycle` (EvictionCycle), the spawn view and the bay under 512
  slots on the ordinary budget, with its picture and a reference launch's
  each bound to a validated, settled frame by its stamp, under 210
  seconds; `rebuild` (RebuildBound), the same cycle under the lift with a
  quota of 32 tiles a boundary and the stale mode, each phase publishing
  at exactly its frames, about 105 seconds; `held` (HeldPartial), the
  spawn's construction held partial by the lift, a quota of 32 tiles and
  8 rows, and ONCE through its screen and E, about 13 seconds; and
  `reuse` (SlotReuse), full-bright lumels with worker 2 held until the
  join releases it, the spawn's return from the yard leaving one tile in
  construction in a slot a yard tile left, its picture checked against
  the bright view held off its tiles and the partial tile read row by
  row, under 60 seconds. The yard draws none of the spawn's materials:
  under full-bright lumels a tile's texels are its material's at its
  level and tile, so a view sharing materials can leave a partial its own
  key's texels. `eviction.nu on-debug <out> [fixture...] [--image
  <image>]` runs them on the checkout's debug build or another image;
  each fixture's result and runtime land in `<out>/<fixture>.nuon`.
  `cadence` holds the cadence fixtures alone on a debug image.
- A picture is bound the way jab's handoff fixture binds one: every
  launch sends the M frame's stamp first, takes its screen with
  `--screen` while the run goes on, and writes E after the screen.
  `picture-refusals` reads a launch's evidence, its measurement, its
  capture, its phase's first frame, and the times of the screen's
  completion and E's write, and returns what it refuses, in prerequisite
  order: the measurement incomplete or invalid; the capture absent or its
  stamp unreadable; the stamp naming no frame after the phase's last
  build and before the end marker; a frame from the one after that build
  through the displayed one unsettled; and either time missing, or E not
  after the screen. The stamp's helpers are fierce's picture module's,
  imported. In `held` a live picture is refused as unsettled alone.
- A run goes on past its E to the launch's bound, so its records hold
  frames after the end marker; a cut meant to drop the marker cuts at
  the marker's own record, the first of its kind.
- A picture's window can start at a placement the guest recorded: the
  launch is measured with a leg a placement, so a frame's leg names the
  placements it drew under and a placement's frame is the first of its
  leg. `reuse` binds its run after its final spawn placement, with a
  publication there required, and its reference from its own placement.
- `qualification` reads a target's bench run through jab's gauge, its
  `bench-doc` for each run's standing and its `run-request` for each
  run's identity, and holds every identity to the candidate's record and
  the target's spec row. Its cases are a table, each a kind, a reading,
  and each target's steps by label; the diagnostics another, each the
  route legs and the summary fields it reads. The bench is held to the
  candidate's bench file read from jab's git at the candidate's commit,
  so a record can be made from a bench run copied off another host; a
  packaged run to that file as its package runs it. A packaged run's
  record reads the manifest its preflight kept beside the run,
  `preflight/package.nuon`: the candidate's file, image, kernel, and
  assets held to it, the image's ELF taken from it, the export's, whose
  symbol table carries RELEASE where the candidate's tree build's does not,
  and the manifest named in the bench's row. An acceptance verdict needs a
  finite play median, a float judged by its text, since nushell 0.115.1
  reads every finite number equal to `inf`. Every run is held to
  its step's conditions, the service, the workers, the cadence, the window
  and the sound, the pad, and the probe; to its step's build, the
  candidate's release build or the named build its words run as
  `{build:<name>}`; the bench to one host and one QEMU; each case to one
  backend. The service active's verdicts judge each run's service window,
  one closed whole with no quota skipped; the feature unavailable reads the
  start's refusal under the floor; the audio reads each debug run's driver
  counters and, where its sound was recorded, its 50 ms windows. A case a
  target holds no step of is not applicable there. The readers that wrote a record are its
  provenance, never a refusal: the check judges the evidence under the
  current readers and keeps a stored answer that differs as history. Its
  presentation row is `proberuns analyse-runs` over the probed runs, each
  by the directory the record found for it: every run's bundle checked,
  its pairing established, and its shown, superseded, and repeated frames
  pooled; a run left unread names its stage and refusals. Every final
  obligation is a row of the ledger, met, failed, pending on its
  dependency, or not applicable; the preparation subset's verdict and the
  final one are read apart.
- `proberuns` is ProbeRuns' reader, `nu/bin/nuance/fierce/proberuns.nu
  <base> <out.nuon> <label>...`: each probed run's capture, bundle,
  flips, and pairing read in turn, a run failing one left unread with its
  refusals, then the renders' selections, the frames shown, superseded,
  repeated, and unshown, and the presented, upload, render, and shown
  intervals, pooled per cadence and leg. A stall on an outer bound is no
  stall. Its `observer` verb reads the observer sets through `observer`.
  `analyse-runs` reads and pools any list of runs, each a label, a run,
  and its directory, which the qualification's record takes.
  Its consumer rows let `runner reread` hold a restoration to it, the base
  `{tree}/..` and the label `tree` for a run landed as one battery.
- `observer` is ProbeRuns' observer control as a function: two arms of
  runs, each a name and its whole-run summary, every measure's arm
  statistics, effect, noise, and whether it is within it. ProbeRuns'
  reader takes it too. Its presentation measures are the acceptance
  interval's median and 95th, between consecutive presents' acceptance
  stamps, with the completion interval, between their flips' ends, as
  measures of their own (AcceptanceInterval); a run read before schema 7
  holds no acceptance interval and is a problem, never a completion
  standing in.
- `footprint` takes its still copies, its stamps, and its bindings from
  `workerparity`'s `disk-of` and `answered-frames` and jab's gauge, and
  each image's provenance from `freeze`'s `provenance-of`. Its pose set
  is the data checkout's `assets/fierce/poses/footprint.nuon`, each pose
  a map, the eye, and the three angles, roll among them, which it sends in
  a P frame of its own; a pose may name its kind of images (`images:
  clamp`), the witness its plan recorded (`witness`), the androids its
  disk keeps (`keep`), and the actors' hold (`hold`), the console's A. A
  LEVELS capture's frame must be drawn from one packet, since a flush
  restarts the span indices its pixels carry, and its snapshot, the X's
  export, must bind to that frame. Every launch's load line must give the
  lumel bake the crate replicates, since the crate counts a lit surface's
  coordinates from its map's origin. A view's five launches take about 27
  seconds each alone.
- `workerparity` draws a map's still copy by the serial backend and by
  workers, a launch a pose and mode. The copy is built from the
  checkout's map with its androids dropped, by jab's suite's
  `variant-tree`, so nothing in the scene moves with time. Every launch
  is stamped and takes its screen while the run goes on, E after it, the
  bound ending the run (status 124). Each picture is bound to the frame
  it shows by jab's gauge (`screen-frame`): that frame settled, at the
  pose sent, drawn by the mode's workers and grain, and under `--cancel`
  its witness by the mode's rule. Each picture is compared with the
  serial backend's of its pose, the stamp's cells skipped. One more
  launch takes its screen between the two placements and must be refused
  for its stamp alone.
- The pose lists for the captures are asset data in the data checkout,
  `assets/fierce/poses/`: `census_render_1.nuon` and
  `render_1_settled.nuon` on Render One, `census_still.nuon` on Render
  Zero's still copy, `spawn.nuon`, Render Zero's spawn, and
  `footprint.nuon`, the level comparison's seventeen views on both maps'
  still copies, the clamp pose `garage_far_clamp`, and the held android
  `android_near` on a copy keeping `bay_android_1`.

## What the code expects

- Jab is checked out beside this repository, at `../jab`. The modules
  import its modules by paths relative to their own files.
- The data checkout is beside it too, at `../jab-stress-data`: the pose
  lists a command reads are its `assets/fierce/poses/`, and a run's
  record goes to its `runs/`.
- A command that runs the debug build finds Jab's target through the
  SDK's `target root`, in `nu/mod/fierce/places`: the debug kernel,
  fierce's image, and the still copy's romfs.
