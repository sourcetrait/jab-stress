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
    [--program <dir>]` exports a commit's program and builds it release,
    the export named after its symbols (`export_<commit>-footprint`).
  - `footprint.nu` runs FootprintEstimate's level comparison. `images
    <export>` builds five debug images of one export, each in a copy of
    the export's program named `<export>_<label>`: `picture` and
    `picture_candidate` (debug, and debug with FOOTPRINT) for the
    pictures, `owner`, and `levels` and `levels_candidate` (debug with
    LEVELS, and with LEVELS and FOOTPRINT). Each image keeps the kernel
    built with it as `kernel.elf` and its provenance; their record is
    `footprint_images.nuon` in the export. `capture <export> <poses>
    <out> [--only <poses>]` launches every image at each pose `--only`
    names, comma separated, all of them by default, and runs the
    footprint crate's `reference` and `differ` over the bound captures; a
    pose already captured into `out` is refused. `read <out>` judges the
    views, and `crops <out> <pose>` cuts each region where the two
    pictures differ out of both, side by side.
  - `qualification.nu`: `candidate <out> [--tag <tag>]` builds jab's
    release tree and writes the candidate's record, jab's checkout clean
    and the tag, when given, on its HEAD, this repository's changes and
    tag recorded; `record <bench> <candidate> <target> <out>` writes a
    target's `qualification.nuon` from a bench run of
    `kit/fierce/bench/qual_<target>.nuon`; `check <record>` prints every
    problem the check names and fails on any; `report <paths>` writes the
    report from records, the last path its file, `--compared <file>`
    rendering a `nuance.nu gauge compare` output as the comparison with
    the first baseline. Its module splits into `matrix`, the targets, the
    cases, the diagnostics, the limits, the acceptance rules, and the
    helpers the others share, then `candidate`, `record`, `check`, and
    `report`.
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
  so a record can be made from a bench run copied off another host. The
  readers that wrote a record are its provenance, never a refusal.
- `observer` is ProbeRuns' observer control as a function: two arms of
  runs, each a name and its whole-run summary, every measure's arm
  statistics, effect, noise, and whether it is within it. ProbeRuns'
  reader takes it too.
- `footprint` takes its still copies, its stamps, and its bindings from
  `workerparity`'s `disk-of` and `answered-frames` and jab's gauge, and
  each image's provenance from `freeze`'s `provenance-of`. Its pose set
  is the data checkout's `assets/fierce/poses/footprint.nuon`, each row a
  map, the eye, and the three angles, roll among them, which it sends in
  a P frame of its own. A LEVELS capture's frame must be drawn from one
  packet, since a flush restarts the span indices its pixels carry. A
  pose's five launches take about 27 seconds each alone.
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
  still copies.
- `fps/just/` holds one-line shims over these bins, one justfile a
  purpose, until every consumer calls the bins.

## What the code expects

- Jab is checked out beside this repository, at `../jab`. The modules
  import its modules by paths relative to their own files.
- The data checkout is beside it too, at `../jab-stress-data`: the pose
  lists a command reads are its `assets/fierce/poses/`, and a run's
  record goes to its `runs/`.
- A command that runs the debug build finds Jab's target through the
  SDK's `target root`, in `nu/mod/fierce/places`: the debug kernel,
  fierce's image, and the still copy's romfs.
