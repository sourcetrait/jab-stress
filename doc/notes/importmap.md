# The import-map checker

`nu/mod/nuance/importmap/` holds Jab's and this workbench's nushell trees to
a migration contract while their code moves into modules. The contract,
`assets/jab/importmap/contract.nuon` in the data checkout, says where every
definition is now, where it goes, what it is called there, who may call it,
and what its signature is. The checker reads both trees whole every time it
runs and lists every place they disagree with the contract.

## Running it

```
nu nu/bin/nuance/importmap.nu check <jab checkout> <this checkout> [--landed <groups>] [--out <dir>]
```

`--landed` names the groups of moves that have landed, comma separated,
such as `KitFierce,SdkModules/1`. With `--out`, the report goes to
`<dir>/report.nuon`; it lands in the data checkout as a run of
`runs/jab/importmap/`. The run prints whether the trees hold, the count of
refusals, and what it read, in under a minute here. The checker is a bin of
its own, since its closures copy every module a bin has loaded each time
they run: under `nuance.nu`'s imports it took 86 seconds where alone it
takes 47.

The checker parses each source in its own engine, so a call it reads can
resolve to a command its own bin imports under the same words; it counts
such a call the same as one left unresolved.

## What it refuses

- a definition or constant the contract does not own, at its file and
  line;
- a definition in neither its old place nor its new one, in both at once,
  or in its old place after its group has landed; a definition or constant
  its group retires, still there once the group has landed;
- an import in a form it does not resolve, a module's import outside the
  contract's edges, and any cycle of imports; a bin's import bound through a
  constant resolves, `path self <path>` or, for a bin a link runs, the
  directory it resolves first joined with the path;
- a caller outside a family of modules calling one of its internal or
  private definitions;
- a bin's command making more than one call;
- a signature unlike the contract's;
- once the game's suite has moved, a case missing from its part or called
  out of order, and a planned rename or merge not made.

A refusal means the plan changed or a move went wrong. Either way the
contract or the code is corrected; nothing is waved through.

## What it expects

The data checkout beside this one, `../jab-stress-data`, unless
`--contract` names the contract. Both checkouts as they are: it reads the
working trees, not a commit, and records each tree's commit and whether it
holds changes.
