# A log stamp, the shim's seconds and six digits, as whole microseconds
def stamp-us [stamp: string]: nothing -> int {
    let parts = ($stamp | split row ".")
    ($parts.0 | into int) * 1000000 + ($parts.1 | into int)
}

# What the renders select of the paired uploads, by the log's order
export def main [events: list<any>, pairs: list<any>]: nothing -> record<renders: int, frames: list<any>> {
    mut uploads = 0
    mut previous: any = null
    mut renders = []
    for e in $events {
        if $e.kind == "upload" {
            $uploads += 1
        } else if $e.kind == "render" {
            let us = (stamp-us $e.stamp)
            $renders = ($renders | append { key: $"o($uploads)", ordinal: $uploads, us: $us, gap_us: (if $previous == null { null } else { $us - $previous }) })
            $previous = $us
        }
    }
    let selected = (if ($renders | is-empty) { {} } else { $renders | group-by key })
    let reach = (if ($renders | is-empty) { 0 } else { $renders | get ordinal | math max })
    mut last_upload: any = null
    mut last_shown: any = null
    mut read = []
    for p in $pairs {
        let mine = ($selected | get -o $"o($p.ordinal)" | default [])
        let n = ($mine | length)
        let first_us = ($mine | get -o 0.us)
        $read = ($read | append {
            ordinal: $p.ordinal,
            upload_us: $p.upload_us,
            upload_interval_us: (if $last_upload == null { null } else { $p.upload_us - $last_upload }),
            renders: $n, repeats: ([($n - 1) 0] | math max),
            shown: ($n > 0), superseded: ($n == 0 and $reach > $p.ordinal), unshown: ($n == 0 and $reach < $p.ordinal),
            age_us: (if $n == 0 { null } else { $first_us - $p.upload_us }),
            shown_interval_us: (if $n == 0 or $last_shown == null { null } else { $first_us - $last_shown }),
            render_intervals_us: ($mine | each {|r| $r.gap_us } | compact),
        })
        $last_upload = $p.upload_us
        if $n > 0 { $last_shown = $first_us }
    }
    { renders: ($renders | length), frames: $read }
}
