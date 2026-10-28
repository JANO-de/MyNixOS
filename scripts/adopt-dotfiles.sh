#!/usr/bin/env bash
# Move the current ~/.config app configs into <repo>/dotfiles BEFORE enabling
# modules.desktop.dotfiles (otherwise home-manager would rename them to *.backup
# and ii/Hyprland would start from the package defaults).
# Usage: scripts/adopt-dotfiles.sh [repo-path] [--quickshell]
set -euo pipefail

REPO="$HOME/Proyectos/MyNixOS"
QS=0
for a in "$@"; do
  case "$a" in
    --quickshell) QS=1 ;;
    *) REPO="$a" ;;
  esac
done
DEST="$REPO/dotfiles"
STAMP="$(date +%Y%m%d-%H%M%S)"
CFG="$HOME/.config"

[ -d "$REPO/.git" ] || { echo "Not a git repo: $REPO" >&2; exit 1; }
mkdir -p "$DEST"

adopt() { # <path under ~/.config> <name in dotfiles/>
  local src="$CFG/$1" name="$2"
  if [ -L "$src" ]; then echo "skip   $src (already a symlink)"; return; fi
  if [ ! -d "$src" ]; then echo "skip   $src (missing)"; mkdir -p "$DEST/$name"; return; fi
  if [ -n "$(ls -A "$DEST/$name" 2>/dev/null)" ]; then
    echo "skip   $DEST/$name is not empty; resolve by hand" >&2; return
  fi
  mkdir -p "$DEST/$name"
  # Caches, backups and lock/tmp files stay out of the repo.
  rsync -a \
    --exclude='hyprmon_backups' --exclude='preset-store' \
    --exclude='*.tmp' --exclude='*.lock' --exclude='*.bak' --exclude='.qmlc' \
    "$src/" "$DEST/$name/"
  mv "$src" "$src.pre-dotfiles-$STAMP"
  echo "adopt  $src -> $DEST/$name   (original kept as $src.pre-dotfiles-$STAMP)"
}

adopt hypr hypr
adopt hyprmon hyprmon
adopt illogical-impulse illogical-impulse
adopt matugen matugen
[ "$QS" -eq 1 ] && adopt quickshell/ii quickshell-ii

echo
echo "Next: git add -A && sudo nixos-rebuild switch --flake .#desktop && hyprctl reload && systemctl --user restart ii"
echo "Rollback: rm the new symlink in ~/.config and mv the *.pre-dotfiles-$STAMP folder back."
