# mod.nu

The regions where a pose's pictures differ, cut out of both (footprint's
regions).

## def crops

Each region where a pose's two pictures differ cut out of both, today's
above or left and the candidate's below or right, `pad` pixels of
context about the box held to the screen, as PNGs under
`<out>/<pose>/crops/`, any made before retired.

- each picture cropped in a list of its own, since an operator acts
  on every image of the list it meets; a wide region stacked, a tall
  one side by side
