#!/usr/bin/env bash
# Adapted from temp/inir-nixos/scripts/auto-update.sh for this flake.
# Optional: pulls + rebuilds automatically, but ONLY if the repo is clean and
# the build succeeds. Never leaves the system half-updated. Notifies either
# way.
set -uo pipefail

FLAKE_DIR="${FLAKE_DIR:-$HOME/Documents/MyNixOS}"
BRANCH="${BRANCH:-main}"
HOST="${HOST:-laptop}"

cd "$FLAKE_DIR" || exit 1

git fetch --quiet origin "$BRANCH" 2>/dev/null || exit 0

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")

[[ "$LOCAL" == "$REMOTE" ]] && exit 0  # already up to date

# Never auto-pull over uncommitted local changes; the rebuild requires a
# clean working tree to resolve the flake anyway.
if ! git diff --quiet --exit-code || ! git diff --cached --quiet --exit-code; then
    notify-send "NixOS auto-update skipped" \
        "Uncommitted changes in $FLAKE_DIR — pull and rebuild manually." \
        -a "NixOS Config" -i dialog-information
    exit 0
fi

if ! git pull --quiet --ff-only origin "$BRANCH"; then
    notify-send "NixOS auto-update failed" \
        "git pull failed — check $FLAKE_DIR manually" -a "NixOS Config" -i dialog-error
    exit 1
fi

if sudo nixos-rebuild switch --flake "$FLAKE_DIR#$HOST" > /tmp/auto-update.log 2>&1; then
    notify-send "NixOS config updated" \
        "Rebuilt successfully from origin/$BRANCH." -a "NixOS Config" -i software-update-available
else
    git reset --hard "$LOCAL" --quiet
    notify-send "NixOS auto-update FAILED — rolled back" \
        "Build broke, repo reverted to last working commit. Log: /tmp/auto-update.log" \
        -a "NixOS Config" -i dialog-error
    exit 1
fi