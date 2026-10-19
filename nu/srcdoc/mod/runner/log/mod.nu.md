# mod.nu

The log container, `Log.nutype`, schema 1: a `.nuonl` file, one record a
line, its header, its chunks, and its trailer, a log's bytes whole as the
file held them. Bytes, never lines: a CR, a lone LF, a last fragment with no
newline, invalid UTF-8, and the spacing of an error's excerpt all survive,
since nothing is split or decoded, and nothing is repaired.

## def wrap

The header `{schema: 1, kind: "log", source, stream, captured}`, `captured`
the original's modification time; the chunks `{seq, bytes}`, 64 KiB at most
each, `seq` from 0 with no gap; the trailer `{end: true, chunks, length,
sha256, terminated}`, the original's length and SHA-256 and whether its last
byte is an LF.

## def original

The original's bytes, chunks in `seq` order, every line held to the model
first; a container whose header, `seq` run, chunk count, length, SHA-256,
or termination disagrees is refused whole, never read in part. `runner log
bytes` prints them.

## def text

The original decoded as UTF-8, `runner log text`.
