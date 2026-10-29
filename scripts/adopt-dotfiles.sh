#!/usr/bin/env bash
# Move this machine's current ~/.config app configs into <repo>/dotfiles/<host>/ BEFORE enabling
# modules.desktop.dotfiles (otherwise home-manager would rename them to *.backup and ii/Hyprland
# would start from the package defaults).
# Usage: scripts/adopt-dotfiles.sh [--host NAME] [--repo PATH] [--quickshell]
#   --host defaults to `hostname`, --repo to ~/Proyectos/MyNixOS
set -euo pipefail

REPO="$HOME/Proyectos/MyNixOS"
HOST="$(hostname)"
QS=0
while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --quickshell) QS=1; shift ;;
    *) echo "unknown argument: $1" >&2; exit 1 ;;
  esac
done
DEST="$REPO/dotfiles/$HOST"
STAMP="$(date +%Y%m%d-%H%M%S)"
CFG="$HOME/.config"

[ -d "$REPO/.git" ] || { echo "Not a git repo: $REPO" >&2; exit 1; }
mkdir -p "$DEST"

adopt() { # <path under ~/.config> <name in dotfiles/<host>/>
  local src="$CFG/$1" name="$2"
  if [ -L "$src" ]; then
    local real; real="$(readlink -f "$src")"
    case "$real" in
      /nix/store/*|"$DEST"/*)
        echo "skip   $src (already managed -> $real)"; mkdir -p "$DEST/$name"; return ;;
    esac
    # A symlink to something else (e.g. another shell's config dir): do not import its contents.
    mkdir -p "$DEST/$name"
    mv "$src" "$src.pre-dotfiles-$STAMP"
    echo "link   $src pointed to $real: link moved aside, contents NOT copied (starting empty: $DEST/$name)"
    return
  fi
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
echo "Next: git add -A && sudo nixos-rebuild switch --flake .#$HOST && hyprctl reload && systemctl --user restart ii"
echo "Rollback: rm the new symlink in ~/.config and mv the *.pre-dotfiles-$STAMP entry back."
