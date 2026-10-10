# The fps workbench

`fps/` holds recipes, probes, and mutant runners for testing Jab's fps
game beyond its own suite. Nothing in it is generated. Builds, captures,
logs, candidate trees, and mirrors are written outside the repository,
under the session's scratch directory or `$XDGX_TMP_HOME/jab-stress/`.

## Layout

- `fps/just/` holds one justfile per purpose. Run a recipe with
  `just -f fps/just/<name>.just <recipe>`.
  - `handoff.just` builds fps, runs the handoff and builder fixtures
    alone, and runs the handoff probes, the dump reader's mutants, and
    the fps readers. Its `keys` recipe reads a capture's tile dumps as
    each tile's header and the SHA-256 of its texels.
  - `handoff_mutants.just`, `pool.just`, and `census.just` are the
    program mutant runner's `jf` for each mutant set. Their `cand-build`
    and `image-test` recipes build and test a candidate with that set's
    build symbols.
  - `pool.just` also holds the tile pool's readers, the export of a
    commit's image, and the gauge's rules over a mirror of the test files.
  - `census.just` also holds the tile census's reading and the census
    reader's holds.
  - `poses.just` captures a map's poses on an image.
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
    recipes run the join's hold (`fps/probe/join/hold.nu`), and
    `join-cands` lays the join's forced cases out as candidate trees
    (`fps/probe/join/candidates.nu`) for `pool.just`'s `cand-build`.
    `eviction-cands` does the same for the eviction fixtures' forced
    cases (`fps/probe/eviction/candidates.nu`): construction_skipped,
    construction skipped at every fifth frame's boundary, which fails
    `rebuild` at its publication frames and `cycle` at its budget.
- `fps/stress/` holds the release tier's fixtures, the exhaustive tests a
  manual release build runs beside jab's own suite, each asserting and
  run on a debug image. `eviction.nu` holds the tile eviction fixtures:
  `cycle` (EvictionCycle), the spawn view and the bay under 512 slots on
  the ordinary budget, with its picture and a reference launch's each
  bound to a validated, settled frame by its stamp, then each picture's
  negatives, about 210 seconds; `rebuild` (RebuildBound), the same cycle
  under the lift with a quota of 32 tiles a boundary and the stale mode,
  each phase publishing at exactly its frames, about 105 seconds; and
  `held` (HeldPartial), the spawn's construction held partial by the
  lift, a quota of 32 tiles and 8 rows, and ONCE through its screen and
  E, about 13 seconds. `stress.just`'s `eviction image out [fixture...]`
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
  `picture-negatives` proves each refusal on real evidence: the
  unaltered evidence refused for nothing, then one alteration at a time,
  each refused for exactly its kind, a re-written stamp read back each
  time. `held` is the live case, a picture refused as unsettled alone.
- A run goes on past its E to the launch's bound, so its records hold
  frames after the end marker; a cut meant to drop the marker cuts at
  the marker's own record, the first of its kind.
- `fps/probe/` holds the probes, one directory per task: `handoff`,
  `pool`, `eviction`, `join`, and `nu` for probes of nushell's own
  behaviour.
- `fps/readers/` holds the readers of the gauge's batteries and
  captures: `admission.nu`, `poolgauge.nu`, `packetgauge.nu`,
  `workergauge.nu`, `lane.nu`, `tilecensus.nu` with its resolver
  `tilecensus_resolve.nu`, `identity_corrections.nu`, `workerparity.nu`,
  and `export.nu`, which exports a commit's image with its provenance.
  Each runs as `nu <reader> ...` through a justfile's recipe; the readers
  with fixtures of their own run them as `nu <reader> holds ...`.
- `fps/mutants/` holds the standing mutant sets, one `<set>_mutants.nuon`
  a set, each mutant a file, its exact-once finds and puts, and the
  assertion it must fail at; beside them the dump reader's mutant runner
  and the interval mutant set.
- `fps/poses/` holds pose lists for the capture recipes.

## What the recipes expect

- Jab is checked out beside this repository, at `../jab`. The probes
  and the readers import its modules by paths relative to their own
  files, and the justfiles reach it the same way.
- A mutant runner that copies readers to mutate them lays the copies at
  `<scratch>/<mutant>/fps/readers/` beside one link, `<scratch>/jab`, to
  the checkout, so a copy's relative imports resolve as the original's
  do.
- A recipe that runs the debug build finds Jab's target through the
  SDK's `target-root`.
