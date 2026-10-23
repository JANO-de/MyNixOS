#!/usr/bin/env bash
# Hot-reload loop for the Halo shell: no rebuild, no reboot.
# Usage: scripts/halo-dev.sh [surface-ip]     (default 192.168.0.115)
# Copies shell/halo to the Surface and runs it from ~/halo with live reload.
set -euo pipefail
IP="${1:-192.168.0.115}"
cd "$(dirname "$0")/.."
rsync -a --delete shell/halo/ "jano@$IP:~/halo/"
ssh "jano@$IP" '
  export WAYLAND_DISPLAY=wayland-1 XDG_RUNTIME_DIR=/run/user/1000
  export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | grep -v chronos-shell | head -1)
  systemctl --user stop halo 2>/dev/null || true
  systemctl --user stop halo-test 2>/dev/null || true
  systemctl --user reset-failed halo-test 2>/dev/null || true
  systemd-run --user --unit=halo-test --setenv=WAYLAND_DISPLAY --setenv=HYPRLAND_INSTANCE_SIGNATURE \
    quickshell -p "$HOME/halo"
  sleep 2
  journalctl --user -u halo-test -n 25 --no-pager
'
echo
echo "Test on the Surface, or from here:"
echo "  ssh jano@$IP 'quickshell -p ~/halo ipc call shade toggle'"
echo "  ssh jano@$IP 'quickshell -p ~/halo ipc call home toggle'"
