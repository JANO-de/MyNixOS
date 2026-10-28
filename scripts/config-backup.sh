#!/usr/bin/env bash
# Backup/restore the mutable config files used by ii, hyprland, hyprmon.
# Usage:
#   scripts/config-backup.sh backup [dest]   # copy configs to dest (default: ./config-backup-<date>)
#   scripts/config-backup.sh restore [src]   # copy configs from src back into place

set -euo pipefail

PATHS=(
  "$HOME/.config/quickshell/ii"
  "$HOME/.config/hypr"
  "$HOME/.config/illogical-impulse"
  "$HOME/.config/hyprmon"
)

cmd="${1:-backup}"
target="${2:-}"

case "$cmd" in
  backup)
    dest="${target:-./config-backup-$(date +%Y%m%d-%H%M%S)}"
    mkdir -p "$dest"
    for p in "${PATHS[@]}"; do
      if [ -e "$p" ]; then
        rel="${p#$HOME/}"
        mkdir -p "$dest/$(dirname "$rel")"
        cp -a "$p" "$dest/$rel"
      fi
    done
    echo "Backed up to $dest"
    ;;
  restore)
    src="${target:-./config-backup}"
    if [ ! -d "$src" ]; then echo "Source dir not found: $src"; exit 1; fi
    for p in "${PATHS[@]}"; do
      rel="${p#$HOME/}"
      if [ -e "$src/$rel" ]; then
        rm -rf "$p"
        mkdir -p "$(dirname "$p")"
        cp -a "$src/$rel" "$p"
      fi
    done
    echo "Restored from $src"
    ;;
  *)
    echo "Usage: $0 {backup|restore} [dir]"
    exit 1
    ;;
esac
