#!/usr/bin/env nu
# jab's pose module's path, bound at parse time
const POSE = path self ../../../../../jab/kit/fierce/nu/mod/pose
use $POSE

# A map's poses captured on an image and a kernel, the build's symbols named
def main [map: string, image: path, poses: path, out: path, kernel: path, set: string = "debug"] {
    pose capture $map $poses $out --kernel $kernel --image $image --set $set
}
