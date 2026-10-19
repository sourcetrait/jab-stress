# Inventory.nutype

The logical inventory of a landed run, `inventory.nuon`: a row for each
original artifact as its runner wrote it. Each row gives the artifact's
path relative to the run, its role from the landing's class table, its
bytes' length and SHA-256, and its disposition: `kept`, `archived`,
`derived`, or `hash-only`. `reason` says why for the last two and is empty
for the others.
