# Qualification's recipes (FrameCeiling/Qualification.md), shims over the
# qualification bin until JustRetired. `candidate` writes the candidate's
# record at a freeze. `record` writes a target's record from a bench run.
# `check` holds a record to the schema and the acceptance. `report` writes
# the report over records. Run as `just -f fps/just/qualification.just
# <recipe>`.

set shell := ["nu", "-c"]

qualification := justfile_directory() / "../../nu/bin/nuance/fierce/qualification.nu"

# the candidate's record at its freeze, the release tree built first; tag
# names the tag on jab's HEAD, none unless given
candidate out tag="":
    nu {{qualification}} candidate {{out}} --tag '{{tag}}'

# a target's record, qualification.nuon in out, from a bench run's directory
record bench candidate target out:
    nu {{qualification}} record {{bench}} {{candidate}} {{target}} {{out}}

# a record held to the schema and the acceptance, every problem printed
check record:
    nu {{qualification}} check {{record}}

# the report over records, the last path its file; --compared <compare.nuon>
# renders a comparison with the first baseline
report +paths:
    nu {{qualification}} report {{paths}}
