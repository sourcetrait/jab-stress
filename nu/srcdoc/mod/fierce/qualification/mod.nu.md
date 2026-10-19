# mod.nu

FrameCeiling's Qualification, the closing acceptance against actual play on
both targets (FrameCeiling/Qualification.md). An aggregator: its children
hold the code, and this file re-exports them for a consumer.

- `candidate` builds the release tree and writes the candidate's record at
  its freeze.
- `record` reads one target's bench run, a run of the game's
  bench/qual_<target>.nuon, through `gauge bench doc` and every run through
  run-request, into the target's qualification record: the candidate, the
  bench against the candidate's bench file, every run with its standing,
  its identity, and that identity's agreement with the candidate and the
  target, each case of the matrix with its runs, every acceptance run's
  verdict, the controls' readings and the diagnostics' apart, the host, and
  the limits stated.
- `check` holds a record to the schema and the acceptance, every problem
  named.
- `report` writes the document for its reader, a section a target.
- `matrix` holds what they share: the targets, the cases, the diagnostics,
  the limits, and the acceptance's rules.

Its bin: `nu/bin/nuance/fierce/qualification.nu candidate|record|check|report`,
each verb the child's `main`.
