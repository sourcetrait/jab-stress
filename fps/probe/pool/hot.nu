use ../../../../jab/nu/mod/capture

def main [elf: string] {
    let names = [span_fill span_light tile_build mixer_update row_crossings span_bound row_range poly_fill span_record packet_render band_render]
    capture hot $elf $names | select name start end paged ecalls | to nuon | print
}
