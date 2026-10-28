# mod.nu

The live trees as the checker reads them: sources, declarations,
signatures, and calls, every one by nushell's own parser or tokens.

## const SKIP

`.git`, `.target`, and `extern`, whose links reach a toolchain's tree,
wherever they stand, and beside them each cargo target, the `target`
beside a `Cargo.toml` (`sources-of`), never a `target` elsewhere, since
the SDK's `target` module and its mirror are sources; `glob` is told not
to walk any of them.

## def declarations-of

A top-level `def` or `const` at the start of a line, the form every source
here writes; a quoted name, `def "main build"`, is read whole. The
extractor's `declarations-of` is the same rule, so the contract and the
checker read one declaration one way.

## def sources-of

Every nu file and every runner's body, `nu/nuon/runner/*.nuon`, each
tagged with its kind, since a descriptor's body may import the long
engine. A body is its definition's block, the `def execute` line and the
closing brace left out, so the definition is no declaration of the
workbench's.

## def shape-text, dv-text, sig-text, signatures-of

The extractor's signature rendering, verbatim, so the contract's
signatures and the live ones compare as text: every parameter, its shape
and default, every flag, and the input and output types, from `ast --json`.

## def tokens-of

`ast --flatten`: comments and string text carry no tokens, so prose never
reads as a call. A call into a module imported by a relative path is an
external token naming the module, the word after it its verb, since `ast`
resolves a relative `use` against the process's directory.

## def module-calls

Each call through one of the named modules: the module's token and the
argument after it, or, where the parse resolved the call, the internal
call's words, the module's name first. `ast` parses in the checker's own
engine, so a command the checker's bin imports under the same two words, the
workbench's `tiles handoff` beside the suite's, resolves the call it reads;
both forms are one call.

## def call-count

A body's internal calls and its calls through the named modules. A def's
own `def` keyword is one of its internal calls, which the bin rule takes
away.
