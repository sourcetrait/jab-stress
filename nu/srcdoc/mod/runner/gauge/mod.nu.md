# mod.nu

The batteries' hook into fierce's gauge: fierce's own bins under
`<fps>/nu/bin`, run from fierce's directory.

## def measured

fierce's `nu/bin/do.nu build --set debug` for the debug tree, `--set ""`
otherwise, then, when it built, `nu/bin/nuance.nu gauge run --tree <tree>
--runs <runs>` with the batch's flags. The log's text is both commands'
stdout, then both commands' stderr, the order the batteries' logs have
always had; a
failed build ends it with the build's own exit.

## def batch

- the batch's flags gain `--out <base>/<label>` and `--label <label>`, its log
  `<base>/<label>.log`
- a failure raises `<name> <label> exited <exit>` and the log's last six
  lines, the name a battery's where several share a parent

## def compare

- `nu/bin/nuance.nu gauge compare <files> --field <field>`, `--diagnostic`
  when asked, into `<base>/compare_<field>.nuon`, its output
  `compare_<field>.txt`; its exit returned, never raised
