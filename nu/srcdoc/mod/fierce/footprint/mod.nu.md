# mod.nu

FootprintEstimate's comparison of the mip level a block reads (FrameCeiling.md's
FootprintEstimate, with its fix plan's ClampedReference, SpanEndpoint, and
JudgedPopulation), read from its landed sets. `clamp-plan` plans the clamp
pose's threshold and witnesses from a capture at the release floor. `read`
judges the pose set whole, every view's blocks accounted for by class before
any count, by the declared criteria and the revised one; `crops` cuts each
region where a view's pictures differ out of both. `reread` reads a landed run
again from its restoration, each pose's disk rebuilt, its launches bound
again, its reference taken anew at today's revision, the first reading kept
beside the new (EvidenceRetention's removal gate). Its bin:
`nu/bin/nuance/fierce/footprint.nu read|clamp-plan|crops|reread`.

An aggregator: its children hold the code, and this file re-exports their
verbs for its bin, each by its own name (`footprint read`). No child
imports it; each imports its siblings by path.

- `builds` holds the images' record IMAGES and reads an image's 1/z floor
  (iz-min-of).
- `captures` holds the kinds of pose and their images (KINDS), binds a
  screen to its frame (bind), makes a pose's disk (disk-for), builds the
  crate (footprint-tool), and plans the clamp (`clamp-plan`).
- `verdicts` judges the pose set whole (`read`).
- `rereads` reads a landed run again from its restoration (`reread`).
- `regions` cuts the regions where a view's pictures differ (`crops`).
