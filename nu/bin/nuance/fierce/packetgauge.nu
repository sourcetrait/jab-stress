#!/usr/bin/env nu
# The packetgauge module's path, bound at parse time
const PACKETGAUGE = path self ../../../mod/fierce/packetgauge
use $PACKETGAUGE

# PacketGauge's reading saved to `out` and summarised
def main [mode: string, base: string, out: string, ...labels: string] {
    packetgauge $mode $base $out ...$labels
}
