#!/usr/bin/env bash
# Behaviour-neutral check: drvPath of the three hosts before/after a change.
# usage: beam-plans/drv-check.sh before   (then edit)   beam-plans/drv-check.sh after
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
case "${1:-}" in before | after) ;; *) echo "usage: $0 before|after" >&2; exit 2 ;; esac
git add -A
out="/tmp/mynixos-drv-$1.txt"
for h in desktop laptop halos1; do
  printf '%s %s\n' "$h" "$(nix eval --raw ".#nixosConfigurations.$h.config.system.build.toplevel.drvPath")"
done | tee "$out"
if [ "$1" = after ]; then
  diff -u /tmp/mynixos-drv-before.txt "$out" && echo IDENTICAL
fi
