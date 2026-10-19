# mod.nu

TileHandoff's fixtures run alone on jab's debug tree, outside jab's suite: the
suite's `handoff-holds` and `builder-holds` from fierce's `suite/tiles`, over
the game's `render_1` map, each with the debug kernel and image from `places`.
Its bin: `nu/bin/nuance/fierce/probe/handoff.nu holds|builder|builder-on`.

## def holds

- the build symbols `DEBUG,COUNT`, the reading saved as `handoff_read.nuon` in
  `out`, then `took <duration>` printed, the fixture's wall time

## def builder

- the build symbols `DEBUG`, the reading saved as `builder.nuon` in `out` and
  printed without its `by_level` rows

## def builder-on

- another image in the debug image's place; the reading printed alone, nothing
  saved, as the recipe it replaces did
