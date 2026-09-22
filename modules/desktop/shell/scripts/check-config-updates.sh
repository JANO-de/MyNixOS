#!/usr/bin/env bash
# Adapted from temp/inir-nixos/scripts/check-config-updates.sh for this flake.
# Checks whether $FLAKE_DIR has upstream commits not yet pulled.
# Does not pull or apply anything automatically.
# Shell out via systemd with a clean-ish environment: HOME is set by the
# user manager, everything else we need comes from the unit's PATH.
set -Eeuo pipefail

FLAKE_DIR="${FLAKE_DIR:-$HOME/Documents/MyNixOS}"
BRANCH="${BRANCH:-main}"

command -v git >/dev/null 2>&1 || exit 0
command -v notify-send >/dev/null 2>&1 || exit 0

[[ -d "$FLAKE_DIR/.git" ]] || exit 0

cd "$FLAKE_DIR"

git fetch --quiet origin "$BRANCH" 2>/dev/null || exit 0

read -r LOCAL_ONLY REMOTE_ONLY < <(
    git rev-list --left-right --count "HEAD...origin/$BRANCH"
)

if (( REMOTE_ONLY > 0 && LOCAL_ONLY == 0 )); then
    LATEST_MSG="$(git log "origin/$BRANCH" -1 --pretty=%s)"

    notify-send \
        "NixOS config update available" \
        "$REMOTE_ONLY new commit(s). Latest: $LATEST_MSG\n\nRun: cd $FLAKE_DIR && git pull && sudo nixos-rebuild switch --flake .#laptop" \
        -a "NixOS Config" \
        -i software-update-available

elif (( REMOTE_ONLY > 0 && LOCAL_ONLY > 0 )); then
    notify-send \
        "NixOS config repository diverged" \
        "Local and remote histories have diverged. Review $FLAKE_DIR before pulling." \
        -a "NixOS Config" \
        -i dialog-warning
fi