use (path self ../../../../../jab/nu/mod/nutype)

# A container's model
const MODEL = path self ../../../type/data/Log.nutype

# A chunk's bytes at most
const CHUNK = 65536

# A file wrapped as a log container: its header, its chunks, its trailer
export def container [file: path, container: path, source: string, stream: string]: nothing -> nothing {
    let b = (open --raw $file | into binary)
    let n = ($b | bytes length)
    let count = (if $n == 0 { 0 } else { ($n + $CHUNK - 1) // $CHUNK })
    let captured = (ls -l $file | get 0.modified)
    let header = { schema: 1, kind: "log", source: $source, stream: $stream, captured: $captured }
    let chunks = (0..<$count | each {|i| { seq: $i, bytes: ($b | bytes at ($i * $CHUNK)..<([(($i + 1) * $CHUNK) $n] | math min)) } })
    let last = (if $n == 0 { 0x[] } else { $b | bytes at ($n - 1)..<$n })
    let trailer = { end: true, chunks: $count, length: $n, sha256: ($b | hash sha256), terminated: ($last == 0x[0a]) }
    [$header] ++ $chunks ++ [$trailer] | each {|r| $r | to nuon } | str join "\n" | $in + "\n" | save -f $container
}

# A container's original bytes, its chunks in order; refused unless whole
export def original [container: path]: nothing -> binary {
    let lines = (open --raw $container | decode utf-8 | lines)
    let model = (open --raw $MODEL | decode utf-8)
    mut recs = []
    for e in ($lines | enumerate) {
        let r = (try { $e.item | from nuon } catch { null })
        if $r == null { error make { msg: $"($container) line ($e.index + 1) is no NUON record" } }
        let p = (nutype problems $r $model $MODEL)
        if ($p | is-not-empty) { error make { msg: $"($container) line ($e.index + 1): ($p | str join '; ')" } }
        $recs = ($recs | append $r)
    }
    if ($recs | length) < 2 { error make { msg: $"($container) holds no header and trailer" } }
    let header = ($recs | first)
    let trailer = ($recs | last)
    if ($header | get -o kind) != "log" or ($header | get -o schema) != 1 { error make { msg: $"($container) opens with no log header of schema 1" } }
    if ($trailer | get -o end) != true { error make { msg: $"($container) ends with no trailer" } }
    let chunks = ($recs | skip 1 | drop 1)
    if ($chunks | any {|c| ($c | get -o seq) == null }) { error make { msg: $"($container) holds a record past its header that is no chunk" } }
    if ($chunks | get seq) != (0..<($chunks | length) | each {|i| $i }) { error make { msg: $"($container)'s chunks run ($chunks | get seq | to nuon), not 0 on without a gap" } }
    if ($chunks | length) != $trailer.chunks { error make { msg: $"($container) holds ($chunks | length) chunks where its trailer counts ($trailer.chunks)" } }
    let b = ($chunks | get bytes | bytes collect)
    let n = ($b | bytes length)
    if $n != $trailer.length { error make { msg: $"($container)'s chunks hold ($n) bytes where its trailer counts ($trailer.length)" } }
    if ($b | hash sha256) != $trailer.sha256 { error make { msg: $"($container)'s chunks are not the SHA-256 its trailer names" } }
    let last = (if $n == 0 { 0x[] } else { $b | bytes at ($n - 1)..<$n })
    if ($last == 0x[0a]) != $trailer.terminated { error make { msg: $"($container)'s trailer says terminated ($trailer.terminated), where its last byte says otherwise" } }
    $b
}

# A container's original decoded as UTF-8
export def text [container: path]: nothing -> string {
    original $container | decode utf-8
}
