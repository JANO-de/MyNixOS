#!/usr/bin/env bash
# Drop old Surface generations (keeps the newest 2) and rewrite the boot menu.
# Usage: scripts/halos1-clean.sh [halos1-ip]
set -euo pipefail
IP="${1:-192.168.0.115}"
exec ssh -t "jano@$IP" 'sudo nix-env -p /nix/var/nix/profiles/system --delete-generations +2 && sudo /nix/var/nix/profiles/system/bin/switch-to-configuration boot && sudo nix-collect-garbage'
