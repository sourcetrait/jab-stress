# mod.nu

The places a fixture or a probe reads from jab's debug tree, the build `./do
build --set debug` leaves in the sibling checkout's target: the kernel's ELF,
fierce's image, and the still copy's romfs. Each `on-debug` verb takes them
from here, an `--image` naming another image in fierce's place, so a recipe
that resolved `target root` inline is one call.

## def main

- the target is the SDK's `target root` over the sibling checkout, so a
  checkout building under the XDG cache and one keeping `.target` resolve
  alike
- nothing is built or checked: a missing file fails at its launch, as the
  recipes' did
