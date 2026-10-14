# Synthetic batches for the readers' own holds (SelectionIdentity): a
# batch a directory under a base holding gauge.nuon as `gauge run` writes
# one, its summary the report's one identity, each run's own identity
# embedded in its run, the evidence identity-of reads before the summary,
# and every field the readers read in its rows and its measurement.
# Shared by workergauge.nu, packetgauge.nu, and lane.nu.

# A run's frames on one leg, `walk`, a frame for each [workers grain] pair
# of `drawn`: its clock, its presentation at `cadence`, its packets, its
# workers' rounds, and given `harts`, schema 6's harts record's fields,
# every frame presented a period apart.
export def batch-rows [run: int, cadence: int, drawn: list<any>, harts?: record]: nothing -> list<any> {
    $drawn | enumerate | each {|d|
        let n = $d.index
        {
            run: $run, frame: $n, leg: "walk", entry: ($n == 0), x: 1.0, y: 1.0, sector: 0,
            draw_us: 1000, game_us: 100, critical_us: 1800, hud_us: 50, mix_us: 50, flip_us: 500, report_us: 100,
            await_us: 14000, wait_us: 0, pacing_us: 0, cadence: $cadence,
            flip_status: 0, flip_done_us: ($n * 16667 + 1600), flip_interval_us: (if $n == 0 { null } else { 16667 }),
            submission_age_us: 1600, wakes: 0, flip_attempts: 1, refusals: 0,
            preparation_us: 960, raster_us: 40, clear_us: 10, commands: 3, packet_bytes: 1016, flushes: 1, invalidated: 0,
            workers: ($d.item | get 0), grain: ($d.item | get 1), slowest_us: 30, busy_us: 55, dispatch_us: 2, barrier_us: 1,
            tiles_built: 0,
        } | merge ($harts | default {})
    }
}

# A batch written under `base` as `label`, its gauge.nuon's path: the
# summary, then a run for each of `runs`, a record of its `identity`, its
# `cadence`, its `drawn` frames (batch-rows), and optionally its `harts`,
# complete, valid, and seeded at schema 4, or at 6 with harts, its
# measurement's cadences, workers, grains, grants, and active masks its
# rows'.
export def write-batch [base: path, label: string, summary: record, runs: list<any>]: nothing -> string {
    let dir = ($base | path join $label)
    mkdir $dir
    let made = ($runs | enumerate | each {|x|
        let n = ($x.index + 1)
        let harts = ($x.item | get -o harts)
        let rows = (batch-rows $n $x.item.cadence $x.item.drawn $harts)
        {
            run: {
                run: $n, seed: $n, identity: $x.item.identity,
                measured: {
                    clocked: true, complete: true, valid: true, seeded: true, schema: (if $harts == null { 4 } else { 6 }),
                    cadences: ($rows | get cadence | uniq), workers: ($rows | get workers | uniq | sort), grains: ($rows | get grain | uniq | sort),
                    grants: ($rows | each {|r| $r | get -o grant } | compact | uniq | sort), actives: ($rows | each {|r| $r | get -o active } | compact | uniq | sort),
                    outcomes: { rounds: [], androids: [], struck: 0, pickups: 0, sectors: [] },
                },
                ran: { wall_seconds: 10, cpu_seconds: 6 },
            },
            rows: $rows,
        }
    })
    let file = ($dir | path join "gauge.nuon")
    { label: $label, identity: $summary, runs: ($made | get run), rows: ($made | get rows | flatten) } | to nuon | save --raw -f $file
    $file
}
