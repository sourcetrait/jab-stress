# recorded.nuon

Steps through jab's or the workbench's bins, each one's sources, artifacts,
and outputs recorded for landing. The long engine's body alone: the harness
made ready by `nuance.nu runner ready recorded`, then its work launched as
`nuance.nu runner work recorded` with the progress check, the steps recorded
so far against their count, and the bounds, `stress` the workbench's
checkout, whose bin both run.

Its arguments past `stress`, `label`, and `mcp_nom`: `out` the run's
directory, made once; `max_quiet_min` the quiet bound in minutes;
`kernel_source` the commit whose `kernel/` and `sdk/src` jab's checkout must
equal, or empty for none; and `steps`, a table of `name`, `repo` (`jab` or
`stress`), `bin` (its path from that checkout's root, `do` for jab's root
driver), `words`, `symbols` (the build symbols the step's artifacts carry, as
`--set` names them, `DEBUG` among them for a debug build), `programs` (jab
programs whose builds the step records), `fixtures` (`<repo>:<path>` files
whose revisions it records), and `outs` (directories whose new files are its
outputs), `{target}` and `{step}` in a word or an out standing for jab's
target root and the step's own directory.
