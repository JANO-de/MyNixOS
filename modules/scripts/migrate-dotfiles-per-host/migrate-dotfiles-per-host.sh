#!/usr/bin/env bash
# One-time: move the flat dotfiles/<name> folders (first layout) into dotfiles/<host>/<name>.
# Leaves temporary compat symlinks at the old paths so the running session (whose ~/.config links
# still point there) keeps working until the rebuild repoints them.
#
#   migrate-dotfiles-per-host desktop      # 1) move + compat links
#   sudo nixos-rebuild switch --flake .#desktop       # 2) normal rebuild
#   migrate-dotfiles-per-host --cleanup    # 3) remove the compat links
set -euo pipefail

REPO="${REPO:-$HOME/Proyectos/MyNixOS}"
NAMES=(hypr hyprmon illogical-impulse matugen quickshell-ii)
cd "$REPO"

if [ "${1:-}" = "--cleanup" ]; then
  for n in "${NAMES[@]}"; do
    if [ -L "dotfiles/$n" ]; then rm "dotfiles/$n"; echo "removed compat link dotfiles/$n"; fi
  done
  if [ -f .git/info/exclude ]; then
    sed -i '\#^/dotfiles/\(hypr\|hyprmon\|illogical-impulse\|matugen\|quickshell-ii\)$#d' .git/info/exclude
  fi
  exit 0
fi

HOST="${1:?usage: $0 <host> | --cleanup}"
mkdir -p "hosts/$HOST/dotfiles"
for n in "${NAMES[@]}"; do
  if [ -d "dotfiles/$n" ] && [ ! -L "dotfiles/$n" ]; then
    if [ -e "hosts/$HOST/dotfiles/$n" ]; then echo "skip   hosts/$HOST/dotfiles/$n already exists" >&2; continue; fi
    git mv "dotfiles/$n" "hosts/$HOST/dotfiles/$n"
    ln -s "$HOST/$n" "dotfiles/$n"
    # keep the temporary links out of `git add -A`
    grep -qxF "/dotfiles/$n" .git/info/exclude 2>/dev/null || echo "/dotfiles/$n" >> .git/info/exclude
    echo "moved  dotfiles/$n -> hosts/$HOST/dotfiles/$n (compat link left behind)"
  fi
done
echo "Now: sudo nixos-rebuild switch --flake .#$HOST, then: migrate-dotfiles-per-host --cleanup"
