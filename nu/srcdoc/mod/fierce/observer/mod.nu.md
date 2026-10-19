# mod.nu

ProbeRuns' observer control, the sdl shim's effect on the measures of the runs
it was preloaded in (ProbeRuns.md's Observer controls). Two arms of runs, the
shim preloaded in one and the one difference; each run's statistic of each
measure read from its whole-run summary (gauge/measure's leg-summary); an arm's
statistic the median of its runs' by nearest rank; the effect the probed arm's
less the plain arm's; the noise half the larger of the two arms' ranges, an
arm's range its greatest run's statistic less its least's; a measure within its
noise when the effect's size is at most the noise. A probed reading stands for
the unprobed program's presentation only when every measure is within its noise
(`admissible`); otherwise its readings are instrumented-only.

## const MEASURES

The measures, each a name and the cell path of its statistic in a run's
whole-run summary: the critical path's, the drawing's, and the flip
phase's medians, and the guest's presented interval's median and 95th.

## def median-of

A list's median by nearest rank, the gauge's statistics' rule; null for
no values.

## def statistic

A run's statistic of a measure, from its whole-run summary; null where
the summary holds none.

## def shim-effect

The shim's effect over two arms, each a list of runs, a run its `name`
and its whole-run summary `whole`: every measure's arm statistics, the
effect, the noise, and whether the effect is within it; `problems`
naming an arm with no run and each run lacking a statistic, a measure
with a problem never within its noise; `admissible` when there is no
problem and every measure is within its noise.
