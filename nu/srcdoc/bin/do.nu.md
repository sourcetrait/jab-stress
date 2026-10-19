# do.nu

The workbench's casual driver, linked as `do` at the root, resolving itself
first since `path self` names the link. The workbench keeps no `test`: what
it runs tests the product, and nothing in it tests its own tools.

## def main bench

`./do bench <battery> <args>`: a battery, one of the runners' harnesses by
name (`nu/nuon/runner/<battery>.nuon`), run whole in the foreground from the
module its descriptor calls, its arguments a NUON file of the record the
runner takes, `stress` filled in. Its ready, then its work, the result
printed whole as NUON. jab's `./do watch` from another shell records the
QEMU it runs.
