# mod.nu

Every captured pose judged against the pose set, reading.nuon written
(footprint's verdicts).

## const READING_FIELDS

The pose fields a reading takes from the pose set, `witness` and
`derivative`, never a capture's condition: a witness is a judgment over a
capture, so a pose set may gain one after its pose was captured and a reread
reads it (rereads).

## def judged

A level's verdict against a reference level and its band, as the
crate's judge gives it: within the band either level beside its
boundary agrees.

## def blocks-of

A pose's judged blocks (rows.nuon) read block by block: by the declared
reference, the candidate's sharper blocks today's are not (its own) and
those both are; and each estimator's blocks the declared reference
judges off and the secant reference passes, the along-span step's,
since the two references differ in that term alone, with how many of
them the along term decides and the block's step over the start's
derivative there; and the candidate's blocks off the declared reference
where today's agrees with it (`new_off`), its no-new-departure count.

## def verdict-of

A view's verdict by one reference, `prefix` "" the declared one and
"secant_" the secant's: outside the bands the candidate's disagreements,
sharper and coarser, at most today's, and none sharper.

## def departure-of

A view's no-new-departure check by its blocks: the candidate never off
the declared reference where today's agrees with it, and never sharper by
it where today's is not; a departure both share before the change counts
for neither.

## def population-of

JudgedPopulation's rule on a pose: every unresolved class named with its
blocks, at least one block judged, and a held pose's actor blocks judged,
the hold the capture's own; then the witnesses the pose set's record
`listed` names (ClampedReference). A `witness`, a block by its row and
`x0`: judged, clamped, and the candidate's level there the clamped
reference's. A `derivative`, a block by its row and `x0` with its `down`,
the clamped mapping's analytic derivative down a row there, checked
against the row's finite difference when the clamp was planned: judged,
clamped, and the reference's down term there the recorded value exactly,
so the block table's reference still computes the derivative that was
checked. The block table is opened once, and only for a pose with a
witness.

## def read

The pose set's names required whole: a pose missing from `out` or refused
at capture leaves the reading incomplete, never passing on the rest. Each
view's tallies, today's and the candidate's, by the declared reference and
by the secant reference, its clamped blocks beside the floor the reference
held its images to, `iz_min` and its depth `floor_depth` (null for a
capture whose reference recorded none), its population (population-of)
with the pose set's record of it for its witnesses, its verdict by
the criteria (verdict-of), its blocks read one by one (blocks-of), its
no-new-departure check (departure-of), and the pictures' differing pixels
and regions. A view holds only resolved; the criteria hold only when the
reading is whole and every view holds. reading.nuon holds it, the declared
criteria's whole verdict as recorded, and the revised criterion's
(SecantCriterion), the secant's verdicts and no new departure on every
view together.

The revised criterion tests whether the candidate's row estimate gives
the level a block's footprint asks when the along term is the engine's own
step, the secant over the block's true length, and the down term the
analytic derivative at the block's start on the engine's mapping; whether
the engine's along stepping matches the analytic derivative is
AlongSpanFootprint's. The declared criteria's result stands as recorded.
The clamp's limit (ClampedReference): the release floor, IZ_MIN 4096, a
depth of 16,384 m, is reached by no surface of the inventoried content at
the inventoried poses, so the clamp stands proved at the test threshold
alone, IZ_TEST's on the clamp pose. A reading shows it in its data, each
view's clamped blocks beside its `iz_min`: none at the release floor, and
the clamp pose's at IZ_TEST's with its two witnesses held.
