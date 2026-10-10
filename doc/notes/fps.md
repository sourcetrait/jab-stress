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
    the fps readers.
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
    pair run's reading against the views' key sets (`pair-read`).
- `fps/probe/` holds the probes, one directory per task: `handoff`,
  `pool`, `eviction`, and `nu` for probes of nushell's own behaviour.
- `fps/mutants/` holds the dump reader's mutant runner and the interval
  mutant set.
- `fps/poses/` holds pose lists for the capture recipes.

## What the recipes expect

- Jab is checked out beside this repository, at `../jab`. The probes
  import its modules by that relative path, and the justfiles reach it
  the same way.
- A recipe that runs the debug build finds Jab's target through the
  SDK's `target-root`.
- The fps readers and the standing mutant sets are kept outside this
  repository, in `$HOME/ai/two/iter/jab/subiter/fps/operational`, which
  the justfiles name as `ops`.
