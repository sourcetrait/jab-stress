# Qualification's recipes (FrameCeiling/Qualification.md): the candidate's
# record at a freeze, a target's record from a bench run, its check, the
# report, and the holds, each through fps/readers/qualification.nu under
# the real nu. Run as `just -f fps/just/qualification.just <recipe>`.

set shell := ["nu", "-c"]

readers := justfile_directory() / "../readers"

# the candidate's record at its freeze, the release tree built first; tag
# names the tag on both checkouts' HEADs, none unless given
candidate out tag="":
    nu {{readers}}/qualification.nu candidate {{out}} --tag '{{tag}}'

# a target's record, qualification.nuon in out, from a bench run's directory
record bench candidate target out:
    nu {{readers}}/qualification.nu record {{bench}} {{candidate}} {{target}} {{out}}

# a record held to the schema and the acceptance, every problem printed
check record:
    nu {{readers}}/qualification.nu check {{record}}

# the report over records, the last path its file; --compared <compare.nuon>
# renders a comparison with the first baseline
report +paths:
    nu {{readers}}/qualification.nu report {{paths}}

# the holds over synthetic bench runs under scratch, which starts empty
holds scratch:
    nu {{readers}}/qualification.nu holds {{scratch}}
