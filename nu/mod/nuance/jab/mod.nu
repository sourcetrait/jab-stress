# jab's casual driver, checked out beside the workbench
const DO = (path self ../../../../../jab/nu/bin/do.nu | path expand)

# A directory built by jab's driver with the build symbols named
export def build [dir: path, --set: string = ""] {
    ^$nu.current-exe $DO build $dir --set $set
}

# A directory's tests run by jab's driver with the build symbols named
export def test [dir: path, --set: string = ""] {
    ^$nu.current-exe $DO test $dir --set $set
}
