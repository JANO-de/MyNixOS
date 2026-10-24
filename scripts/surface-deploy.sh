#!/usr/bin/env bash
# Rebuild the Surface from this machine and arm the next boot into the Hyprland entry.
# Usage: scripts/surface-deploy.sh [surface-ip]     (default 192.168.0.115)
set -euo pipefail
IP="${1:-192.168.0.115}"
cd "$(dirname "$0")/.."
git add -A   # flakes ignore untracked files
# One password prompt for the SSH connection (reused by nixos-rebuild).
export NIX_SSHOPTS="-o ControlMaster=auto -o ControlPath=$HOME/.ssh/cm-%r@%h -o ControlPersist=15m"

nixos-rebuild boot --flake .#surface \
  --target-host "jano@$IP" --sudo --ask-sudo-password

# Pick the newest hyprland specialisation entry and boot it once (default stays mango).
read -r -d '' REMOTE <<'EOS' || true
export PATH=/run/wrappers/bin:/run/current-system/sw/bin:$PATH
sudo bash -c '
  id=$(bootctl list | awk "/id:/ && /specialisation-hyprland/ {print \$2}" | sort -V | tail -1)
  echo "oneshot -> $id"
  bootctl set-oneshot "$id"
'
EOS
# shellcheck disable=SC2086
ssh -t $NIX_SSHOPTS "jano@$IP" "bash -c $(printf '%q' "$REMOTE")"
echo "Done. Reboot the Surface:  ssh -t jano@$IP sudo reboot"
