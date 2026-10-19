# mod.nu

The checker's rules, each returning its refusals: kind, checkout, file,
line (0 where the rule has none), item, and why.

## def mapped

A coherent group's moves are path prefixes moved whole, KitFierce's
`game/fps/` to `kit/fierce/`; once a group lands, every old path under its
prefix is read at the new one.

## def monolith-files

The families' monoliths at their places once the landed groups moved
them, `kit/fierce/test/gauge.nu` for `game/fps/test/gauge.nu` with
KitFierce landed: what an import of one resolves to, so every rule that
asks whether a file is a monolith asks of where it is. Read at the
contract's old names, a moved monolith drops every consumer and its calls
out of the check without a refusal.

## def name-in-module

A final name is called through its module, `launch plan`, `gauge measure
screen-frame`, `sdl resolve`; inside the module the def is the name less
the module path's words it starts with, or `main` when nothing is left.
A private helper keeps its old name.

## def places

A def that moves is in its old place or its new, never both, and never in
its old once its group has landed; a planned def is absent until its group
lands. A retired def is gone once its group lands; one that stays (test.nu's
`main`, the wrapper) stays. Its signature at the old place is the
contract's old one, at the new place the contract's final one, which differ
where the plan changes a signature (`do-clean` merged into `build clean`).

## def constants

A monolith's constant in its old place, or in its module, or under its
family's modules when the plan names none; a constant may live in several
modules, a child duplicating its parent's few lines.

## def files

A file the contract owns whole keeps its declarations in its place until
its group lands, then under its group's home, any file there.

## def ownership

Every declaration of both trees is one the contract places: a monolith's
def or constant, a module's def by its final name, a case or the
orchestrator's, a bin's `main` verbs, a module's constant of its family,
or an owned file's. Any other is refused at its line.

## def import-rules

Every import resolved; a module's import of another module an edge of the
contract's, an import of a monolith allowed while it stands, a module's
import of any other file refused; and no file on a cycle.

## def def-of

A call through a monolith, where the landed groups put it, names the def
by its old name; a call through a module names it by its name inside the
module; and a call through an aggregator, a module whose children's api it
re-exports (`sdl`), names a child's def by its final name less the
aggregator's words, `sdl log` for sdl/log's `main`.

## def consumer-rules

A consumer is any source outside the family whose module it imports; its
calls through that module, by tokens and by its use list, reach the
contract's defs, and an internal or private one is refused.

## def bin-rules

A bin's verb is one call of one module function: each def's body counted,
its own `def` keyword aside.

## def case-rules

Once FierceModules lands: each case a def of its part with the contract's
signature, `[context: record, records: record]: nothing -> record`, and the
orchestrator's `main` calling each part's case once, in the table's order.

## def transformation-rules

Once its group lands: the clean merged into `build clean`, the probe's
dispatch renamed `probe-kind`, and the byte helpers in `word`.
