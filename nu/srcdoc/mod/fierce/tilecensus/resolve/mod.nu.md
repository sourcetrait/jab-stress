# mod.nu

TileCensus's run binding (GaugeStanding, CensusRunBinding) in a nu of its own,
called by tilecensus and poolgauge: the gauge loaded beside census's parse slows
every command that takes a closure in proportion to the code loaded (41 s
against 5.4 s on one run's log), so the census is read where the gauge is not.
For each request, a report and a run number in it: the run refused unless its
capture is complete and valid; else its directory the one whose identity file
binds to the run's recorded SHA-256, through `gauge identity of` over the
report's run-dirs, the identity's seed the run's; else refused. Its bin,
`nu/bin/nuance/fierce/tilecensus/resolve.nu <requests as NUON>`, prints the
answers as NUON.
