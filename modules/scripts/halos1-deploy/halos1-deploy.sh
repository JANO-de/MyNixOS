#!/usr/bin/env bash
# Rebuild the Surface from this machine. The newest generation is the default boot entry.
# Usage: halos1-deploy [halos1-ip]     (default 192.168.0.115)
set -euo pipefail
IP="${1:-192.168.0.115}"
cd "${MYNIXOS_REPO:-$HOME/Proyectos/MyNixOS}"
git add -A   # flakes ignore untracked files
# One password prompt for the SSH connection (reused by nixos-rebuild).
export NIX_SSHOPTS="-o ControlMaster=auto -o ControlPath=$HOME/.ssh/cm-%r@%h -o ControlPersist=15m"

nixos-rebuild boot --flake .#halos1 \
  --target-host "jano@$IP" --sudo --ask-sudo-password
echo "Done. Reboot the Surface:  halos1-reboot $IP"
