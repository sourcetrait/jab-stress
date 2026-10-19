# Log.nutype

A log container, schema 1: a `.nuonl` file, one record a line, holding one
text log's bytes whole. Its first line is the header, `{schema, kind,
source, stream, captured}`: `source` the producer, such as a runner's
name, `qemu`, `guest`, or `shim`; `stream` `stdout`, `stderr`, or `file`;
`captured` the original's modification time. The chunks follow, `{seq,
bytes}`, each at most 64 KiB, numbered from 0 with no gap. The trailer
closes it, `{end, chunks, length, sha256, terminated}`: the chunk count,
the original's length and SHA-256, and whether its last byte is a line
feed.

Bytes are stored, never lines, so a carriage return, a lone line feed, a
final fragment with no newline, invalid UTF-8, and the spacing of an error
excerpt all survive. A wrapper never repairs its input.
