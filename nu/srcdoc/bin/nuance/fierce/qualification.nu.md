# qualification.nu

The qualification module's command line, each verb one call of the module,
standalone so its closures run in a nu that loads no other module.

## def main candidate

`nu/bin/nuance/fierce/qualification.nu candidate`, its parameters `out: path,
--tag: string = ""`: The candidate's record at its freeze, written to `out`.

## def main record

`nu/bin/nuance/fierce/qualification.nu record`, its parameters `bench: path,
candidate: path, target: string, out: path`: A target's record written to `out`,
its own verdicts printed.

## def main check

`nu/bin/nuance/fierce/qualification.nu check`, its parameters `record: path,
--bench: string = "", --inventory: string = "", --candidate: string = "", --out:
string = ""`: A record derived again from its bench's reopened inputs, its
ledger checked.

## def main report

`nu/bin/nuance/fierce/qualification.nu report`, its parameters `...paths: path,
--compared: string = ""`: The report over checks, the last path its Markdown
file.

## def main package

`nu/bin/nuance/fierce/qualification.nu package`, its parameters `candidate:
path, export: path, target: string, out: path, --stage: string = ""`: The
candidate's host package for a target, one tar from its export.
