# mod.nu

The census's checks that load a jab module in a nu of its own: a module's path
is read at parse time, so a tree given at run time is reached by a child nu
whose source names it, quoted by `to nuon`. Its verb: `nu/bin/nuance.nu fierce
census reader-holds`.

## def reader-holds

- `tree` a jab checkout or an export, its `kit/fierce/nu/mod/census` holding
  `census-reader-holds`, run over the serial log's text; `reader-holds: ok`
  printed once it holds
