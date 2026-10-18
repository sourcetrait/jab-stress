# The fps workbench

`fps/` holds recipes, probes, readers, and stress fixtures for testing
Jab's fps game beyond its own suite. Nothing in it is generated. A run's
record, its logs and results, is kept in the data checkout beside this
repository, `../jab-stress-data`, under `runs/`. Builds, captures, and
candidate trees are written outside both repositories, under the
session's scratch directory or `$XDGX_TMP_HOME/jab-stress/`.

## Layout

- `fps/just/` holds one justfile per purpose. Run a recipe with
  `just -f fps/just/<name>.just <recipe>`.
  - `handoff.just` builds fps, runs the handoff and builder fixtures
    alone, and runs the handoff probes and the fps readers. Its `keys`
    recipe reads a capture's tile dumps as each tile's header and the
    SHA-256 of its texels.
  - `pool.just` holds the tile pool's readers and the export of a
    commit's image. Its `export` takes build symbols as its last
    argument, comma separated, the export then named after them
    (`export_<commit>-footprint`); `cand-build-release` builds release
    with any symbols beside `release`.
  - `footprint.just` runs FootprintEstimate's level comparison through
    `fps/readers/footprint.nu`. `images <export>` builds five debug images
    of one export, each in a copy of the export's program named
    `<export>_<label>`: `picture` and `picture_candidate` (debug, and debug
    with FOOTPRINT) for the pictures, `owner`, and `levels` and
    `levels_candidate` (debug with LEVELS, and with LEVELS and FOOTPRINT).
    Each image keeps the kernel built with it as `kernel.elf` and its
    provenance; their record is `footprint_images.nuon` in the export.
    `capture <export> <out> [only]` launches every image at each pose
    `only` names, comma separated, all of them by default, and runs the
    footprint crate's `reference` and `differ` over the bound captures; a
    pose already captured into `out` is refused. `read <out>` judges the
    views, and
    `crops <out> <pose>` cuts each region where the two pictures differ out
    of both, side by side.
  - `census.just` holds the tile census's reading and the census
    reader over a serial log (`reader-holds`).
  - `qualification.just` runs the qualification's reader,
    `fps/readers/qualification.nu`: `candidate out [tag]` builds jab's
    release tree and writes the candidate's record, jab's checkout clean
    and the tag, when given, on its HEAD, this repository's changes and
    tag recorded; `record bench candidate target out` writes a target's
    `qualification.nuon` from a bench run of
    `game/fps/bench/qual_<target>.nuon`; `check record` prints every
    problem the check names and fails on any; `report +paths` writes the
    report from records, the last path its file, `--compared <file>`
    rendering a `gauge.nu compare` output as the comparison with the
    first baseline.
  - `poses.just` captures a map's poses on an image.
  - `scaling.just` builds the debug and owner candidates a parity reads,
    runs `workerparity.nu`'s parity, its faults, and its judge, runs
    `gaincurves.nu`'s curves and table over a battery, and reads a
    battery's two band heights as matched pairs with `grainpairs.nu`.
  - `layout.just` lays out the tile layout candidates from a commit,
    builds one with any set, and reads a build's hot routines.
  - `smoke.just` runs the development smoke. Its recipe is reconstructed,
    the original file gone; its argument order, seeds then seconds,
    matches the smoke command's source, a static check, never yet run.
  - `eviction.just` runs the tile eviction probes: the pool's counters a
    frame (`rows`); views' key sets at first sight, and two views
    alternated under a slot cap with a dump at every settle, on the
    debug build or another image (`probe`, `probe-on`, `pair`); and a
    pair run's reading against the views' key sets (`pair-read`). The
    probe's `building` mode dumps a settle in pairs, one dump of the
    finished tiles and one asking for the tile in construction too. Its
    `quota` mode runs the work quota's cases under the lift: whole tiles
    to the settle, then one construction a phase under ONCE, each held
    for a dump of the tile in construction. Its `hold` and `hold-on`
    recipes run the join's hold (`fps/probe/join/hold.nu`).
- `fps/stress/` holds the release tier's fixtures, the exhaustive tests a
  manual release build runs beside jab's own suite, each asserting and
  run on a debug image. `eviction.nu` holds the tile eviction fixtures:
  `cycle` (EvictionCycle), the spawn view and the bay under 512 slots on
  the ordinary budget, with its picture and a reference launch's each
  bound to a validated, settled frame by its stamp, under 210 seconds;
  `rebuild` (RebuildBound), the same cycle
  under the lift with a quota of 32 tiles a boundary and the stale mode,
  each phase publishing at exactly its frames, about 105 seconds; and
  `held` (HeldPartial), the spawn's construction held partial by the
  lift, a quota of 32 tiles and 8 rows, and ONCE through its screen and
  E, about 13 seconds; and `reuse` (SlotReuse), full-bright lumels with
  worker 2 held until the join releases it, the spawn's return from the
  yard leaving one tile in construction in a slot a yard tile left, its
  picture checked against the bright view held off its tiles and the
  partial tile read row by row, under 60 seconds. The yard draws none
  of the spawn's materials: under full-bright lumels a tile's texels are
  its material's at its level and tile, so a view sharing materials can
  leave a partial its own key's texels. `stress.just`'s `eviction image out [fixture...]`
  runs them on an image, `eviction-debug out [fixture...]` on the
  checkout's debug build; each fixture's result and runtime land in
  `<out>/<fixture>.nuon`.
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
  after the screen. The stamp's helpers are jab's test.nu's, imported.
  In `held` a live picture is refused as unsettled alone.
- A run goes on past its E to the launch's bound, so its records hold
  frames after the end marker; a cut meant to drop the marker cuts at
  the marker's own record, the first of its kind.
- A picture's window can start at a placement the guest recorded: the
  launch is measured with a leg a placement, so a frame's leg names the
  placements it drew under and a placement's frame is the first of its
  leg. `reuse` binds its run after its final spawn placement, with a
  publication there required, and its reference from its own placement.
- `fps/probe/` holds the probes, one directory per task: `handoff`,
  `pool`, `eviction`, `join`, and `layout`.
- `fps/readers/` holds the readers of the gauge's batteries and
  captures: `admission.nu`, `poolgauge.nu`, `packetgauge.nu`,
  `workergauge.nu`, `gaincurves.nu`, `grainpairs.nu`,
  `lane.nu`, `tilecensus.nu` with its resolver `tilecensus_resolve.nu`,
  `identity_corrections.nu`, `workerparity.nu`, `footprint.nu`,
  `qualification.nu` with the shim control's rule `observer.nu`, and
  `export.nu`, which exports a commit's image with its provenance, the
  game's by default and walk's with `--program example/walk` (the
  kernel's `walk-export`, [Kernel candidates](candidates.md)). Each runs as
  `nu <reader> ...` through a justfile's recipe.
- `qualification.nu` reads a target's bench run through jab's gauge, its
  `bench-doc` for each run's standing and its `run-request` for each run's
  identity, and holds every identity to the candidate's record and the
  target's spec row. Its cases are a table, each a kind, a reading, and
  each target's steps by label; the diagnostics another, each the route
  legs and the summary fields it reads. The bench is held to the
  candidate's bench file read from jab's git at the candidate's commit,
  so a record can be made from a bench run copied off another host. The
  readers that wrote a record are its provenance, never a refusal.
- `observer.nu` is ProbeRuns' observer control as a function: two arms of
  runs, each a name and its whole-run summary, every measure's arm
  statistics, effect, noise, and whether it is within it. ProbeRuns'
  reader takes it too.
- `footprint.nu` takes its still copies, its stamps, and its bindings
  from `workerparity.nu`'s `disk-of` and `answered-frames` and jab's
  gauge, and each image's provenance from `export.nu`'s `provenance-of`.
  Its pose set is the data checkout's `assets/fps/poses/footprint.nuon`,
  each row a map, the eye, and the three angles, roll among them, which it
  sends in a P frame of its own. A LEVELS capture's frame must be drawn
  from one packet, since a flush restarts the span indices its pixels
  carry. A pose's five launches take about 27 seconds each alone.
- `workerparity.nu` draws a map's still copy by the serial backend and
  by workers, a launch a pose and mode. The copy is built from the
  checkout's map with its androids dropped, by jab's test.nu
  `variant-tree`, so nothing in the scene moves with time. Every launch
  is stamped and takes its screen while the run goes on, E after it, the
  bound ending the run (status 124). Each picture is bound to the frame
  it shows by jab's gauge (`screen-frame`): that frame settled, at the
  pose sent, drawn by the mode's workers and grain, and under `--cancel`
  its witness by the mode's rule. Each picture is compared with the
  serial backend's of its pose, the stamp's cells skipped. One more
  launch takes its screen between the two placements and must be refused
  for its stamp alone.
- The pose lists for the capture recipes are asset data in the data
  checkout, `assets/fps/poses/`: `census_render_1.nuon` and
  `render_1_settled.nuon` on Render One, `census_still.nuon` on Render
  Zero's still copy, `spawn.nuon`, Render Zero's spawn, and
  `footprint.nuon`, the level comparison's seventeen views on both maps'
  still copies.

## What the recipes expect

- Jab is checked out beside this repository, at `../jab`. The probes
  and the readers import its modules by paths relative to their own
  files, and the justfiles reach it the same way.
- The data checkout is beside it too, at `../jab-stress-data`: the pose
  lists a recipe reads are its `assets/fps/poses/`, and a run's record
  goes to its `runs/`.
- A recipe that runs the debug build finds Jab's target through the
  SDK's `target-root`.
