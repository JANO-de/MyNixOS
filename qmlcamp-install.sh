#!/bin/sh
# run from ~/Documents/MyNixOS after unzipping
set -e
f=hosts/desktop/default.nix
[ -f "$f" ] || { echo "missing $f: tell Claude your desktop host file path"; exit 1; }
grep -q 'services/qmlcamp' "$f" || sed -i '0,/imports *= *\[/s||imports = [\n    ../../modules/services/qmlcamp|' "$f"
grep -n -A2 'imports' "$f" | head
