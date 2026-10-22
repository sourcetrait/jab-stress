# mod.nu

An export's debug images built with their kernels and provenance, and the 1/z
floor an image was assembled with (footprint's builds).

## const BUILDS

the images, each a label, the set it is built with, and the kind of pose it
serves: for a view, today's picture and the candidate's, the surfaces, and
today's levels and the candidate's; for the clamp, the surfaces and both
levels with IZ_TEST, the debug-only symbol that raises IZ_MIN to 5.5 m, so the
OWNER capture, both LEVELS captures, and their span tables share one floor. The
copy of the export each builds in is `<export>_<label>`.

## const IMAGES

the images' record, in the export's own directory

## def iz-min-of

ClampedReference's provenance rule: the floor is the integer the image was
assembled with, read from its ELF's `IZ_MIN` symbol by the toolchain's nm, never
a symbol's name or a nominal distance; 4096 on an ordinary debug build and
12,201,612 under IZ_TEST.

## def program-of

The export's program directory, the one holding a manifest.

## def images

The images of an export (BUILDS), each its program copied beside the
export as `<export>_<label>`, its src/, manifest, and source.nuon, the
manifest still naming the export's SDK and the checkout's workspace;
the checkout's kernel and then the copy built debug with its set by the
checkout's tool; its flags holding DEBUG and every symbol of its set;
that kernel copied beside it as `kernel.elf` with its loaded bytes,
objcopy's flat image, as `kernel.bin`, every image's the same; and
provenance.nuon beside it. The record, every image's label, set, kind,
image, kernel, digests, and IZ_MIN, goes to the export's IMAGES.
