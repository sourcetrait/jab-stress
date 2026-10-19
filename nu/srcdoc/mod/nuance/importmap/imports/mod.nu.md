# mod.nu

The imports the checker resolves, every other form refused naming its file
and line, and the cycle check over what they reach.

## const LEAVES

The external leaves a graph stops at: nushell's bundled `std`, and the long
engine a runner's body imports, `rig/sourcetrait/emptwo/prototype/long`.

## def lines-of

`use`, `export use`, `source`, and `overlay use` at the start of a line or
of a statement after a `;` on it, the path quoted, bare, or named through
`(path self <path>)`, the nu trees' form, which is read as that path since
`path self` resolves it against the file's directory as a bare one is, and
the list in brackets that follows it: a one-line body, `use <a>; use <b>
[...]; let ...`, holds two imports, and its first path would otherwise
carry the `;`.

## def path-consts

A source's `const NAME = "path"` and `const NAME = path self <path>`, read
for a `use $NAME [...]`. A bin binds its imports so, nushell keeping one
module per path as joined: a bin's bare `use ../mod/map` beside a module's
`use (path self ..)` of the same map loads it twice, `path self` normalizing
the one and not the other. A bin a link runs, jab's root `do`, binds its own
directory first, `const HERE = (path self | path expand | path dirname)`,
since `path self` names the link and not the file, then each import
`const NAME = ($HERE | path join <path> | path expand)`, read as `<path>`
from the file's directory, as `path self <path>` is, when `HERE` is so
defined in the same source.

## def target-of

The path an import names, through its constant when the import names one,
so a rule reads a bound import as the path it binds.

## def resolve

A literal path is resolved against the importing file's directory, a file
or a module directory with its `mod.nu`; a path through the sibling
checkout is that checkout's file. The path is resolved as the system opens
it, links followed, the way the checkouts' roots are, so a sibling reached
through a link is still its checkout. Refused: `overlay use`, a path built at
run time, an absolute path, a path that names nothing, a path outside both
checkouts, and the long engine outside a runner's body.

## def cycles-of

Every file that reaches itself through the imports, by a walk from each.
