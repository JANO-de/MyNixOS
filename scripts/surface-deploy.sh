#!/usr/bin/env bash
# Rebuild the Surface from this machine and arm the next boot into the Hyprland entry.
# Usage: scripts/surface-deploy.sh [surface-ip]     (default 192.168.0.115)
set -euo pipefail
IP="${1:-192.168.0.115}"
cd "$(dirname "$0")/.."
git add -A   # flakes ignore untracked files

nixos-rebuild boot --flake .#surface \
  --target-host "jano@$IP" --sudo --ask-sudo-password

# Pick the newest hyprland specialisation entry and boot it once (default stays mango).
ssh -t "jano@$IP" "sudo sh -c '
  id=\$(bootctl list | awk \"/id:/ && /specialisation-hyprland/ {print \\\$2}\" | sort -V | tail -1)
  echo \"oneshot -> \$id\"
  bootctl set-oneshot \"\$id\"
'"
echo "Done. Reboot the Surface:  ssh jano@$IP sudo reboot"
