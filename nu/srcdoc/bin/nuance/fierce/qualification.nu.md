# qualification.nu

The qualification module's command line, each verb one call of the module, standalone so its closures run in a nu that loads no other module.

## def main candidate

`nu/bin/nuance/fierce/qualification.nu candidate`, its parameters `out: path, --tag: string = ""`: the candidate's record at its freeze, written to `out`.

## def main record

`nu/bin/nuance/fierce/qualification.nu record`, its parameters `bench: path, candidate: path, target: string, out: path`: a target's record written to `out`, its check's problems printed.

## def main check

`nu/bin/nuance/fierce/qualification.nu check`, its parameters `record: path`: a record held to the schema and the acceptance, every problem printed.

## def main report

`nu/bin/nuance/fierce/qualification.nu report`, its parameters `...paths: path, --compared: string = ""`: the report over records, the last path its Markdown file.
