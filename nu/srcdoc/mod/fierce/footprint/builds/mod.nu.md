# mod.nu

The images' record of a landed footprint set and the 1/z floor an image was
assembled with (footprint's builds).

## const IMAGES

the images' record, in an export's own directory: each image's label, set,
kind, image, kernel, digests, and IZ_MIN. A view's images are its picture,
its surfaces, and its levels, and a clamp pose's its surfaces and levels at
the clamp's test floor; the landed sets also hold the FOOTPRINT candidate's
`picture_candidate`, `levels_candidate`, and `levels_candidate_clamp`, read
by their labels (captures' KINDS). A record with no IZ_MIN leaves the floor
to the image's archived ELF (rereads' floor-of).

## def iz-min-of

ClampedReference's provenance rule: the floor is the integer the image was
assembled with, read from its ELF's `IZ_MIN` symbol by the toolchain's nm, never
a symbol's name or a nominal distance; 4096 on an ordinary debug build and
12,201,612 on the landed clamp images.
