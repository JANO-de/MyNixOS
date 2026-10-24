#!/usr/bin/env bash
# Usage: scripts/halo-ipc.sh call shade toggle   (talks to the halo-test shell on the Surface)
set -euo pipefail
IP="${HALO_IP:-192.168.0.115}"
SSHO=(-o ControlMaster=auto -o "ControlPath=$HOME/.ssh/cm-%r@%h" -o ControlPersist=10m)
ssh "${SSHO[@]}" "jano@$IP" "export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1; \
  qs=\$(ls -d /nix/store/*-quickshell-0.3.0/bin/quickshell | tail -1); \
  \"\$qs\" -p ~/halo ipc $*"
