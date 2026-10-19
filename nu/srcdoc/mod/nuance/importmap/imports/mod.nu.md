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
the list in brackets that follows it: a recipe's one-line body, `use
<jab.nu>; use <test.nu> [...]; let ...`, holds two imports, and its first
path would otherwise carry the `;`.

## def path-consts

A source's `const NAME = "path"`, read for a `use $NAME [...]`.

## def resolve

A literal path is resolved against the importing file's directory, a file
or a module directory with its `mod.nu`; a path through the sibling
checkout is that checkout's file. The path is resolved as the system opens
it, links followed, the way the checkouts' roots are, so a sibling reached
through a link is still its checkout. Refused: `overlay use`, a path built at
run time, an absolute path, a path that names nothing, a path outside both
checkouts, and the long engine outside a runner's body. A recipe's path
runs through a placeholder, so it is read by the monolith whose path it
ends with, the monoliths given where the landed groups have put them, or
by the module whose directory it ends with, `{{jab}}/nu/mod/target` the
SDK's `target`, the longest match when two end it; otherwise it is left
unread.

## def cycles-of

Every file that reaches itself through the imports, by a walk from each.
