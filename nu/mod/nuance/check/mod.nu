# A file checked as a module, or by nu's IDE check with --ide, as nu reports it
export def main [file: path, --ide] {
    if $ide { ^$nu.current-exe --ide-check 50 $file } else { nu-check --as-module $file }
}
