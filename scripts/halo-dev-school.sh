#!/usr/bin/env bash
# Hot-reload loop for the Halo shell: no rebuild, no reboot.
# Usage: scripts/halo-dev.sh [surface-ip]     (default 192.168.0.115)
# The Surface must be logged into the *hyprland* boot entry.
set -euo pipefail
IP="${1:-192.168.9.111}"
cd "$(dirname "$0")/.."

# One password prompt for the whole run (connection is reused).
SSHO=(-o ControlMaster=auto -o "ControlPath=$HOME/.ssh/cm-%r@%h" -o ControlPersist=10m)

rsync -a --delete -e "ssh ${SSHO[*]}" shell/halo/ "jano@$IP:~/halo/"
# Before the first rebuild /etc/halo/wallpapers does not exist yet: copy the wallpapers to the picture folder.
if ! ssh "${SSHO[@]}" "jano@$IP" 'test -d /etc/halo/wallpapers'; then
  rsync -a --ignore-existing -e "ssh ${SSHO[*]}" assets/wallpapers/ "jano@$IP:~/Pictures/Wallpapers/"
fi

ssh "${SSHO[@]}" "jano@$IP" 'bash -s' <<'REMOTE'
set -u
export XDG_RUNTIME_DIR=/run/user/1000
export PATH="/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"
qs=$(command -v quickshell || true)
[ -n "$qs" ] || qs=$(ls -d /nix/store/*-quickshell-*/bin/quickshell 2>/dev/null | tail -1 || true)
if [ -z "$qs" ]; then echo "!! quickshell not found on the Surface"; exit 1; fi
echo "quickshell: $qs"
sig=$(ls /run/user/1000/hypr 2>/dev/null | grep -v chronos-shell | head -1 || true)
sock=$(ls /run/user/1000 2>/dev/null | grep -E '^wayland-[0-9]+$' | head -1 || true)
if [ -z "$sig" ] || [ -z "$sock" ]; then
  echo "!! Hyprland is not running on the Surface (you are in mango or logged out)."
  echo "   Boot the hyprland entry first: scripts/surface-deploy.sh, or on the Surface:"
  echo "   sudo bootctl set-oneshot <id from: bootctl list | grep hyprland>; reboot"
  exit 1
fi
export WAYLAND_DISPLAY="$sock" HYPRLAND_INSTANCE_SIGNATURE="$sig" QT_QPA_PLATFORM=wayland
[ -e "$XDG_RUNTIME_DIR/kbd-visible" ] || echo hidden > "$XDG_RUNTIME_DIR/kbd-visible"
systemctl --user stop halo halo-test 2>/dev/null || true
systemctl --user reset-failed halo-test 2>/dev/null || true
systemd-run --user --unit=halo-test \
  --setenv=WAYLAND_DISPLAY --setenv=HYPRLAND_INSTANCE_SIGNATURE --setenv=QT_QPA_PLATFORM \
  "$qs" -p "$HOME/halo"
sleep 3
journalctl --user -u halo-test --since '-20s' --no-pager | tail -30
REMOTE

echo
echo "Test: ssh jano@$IP 'quickshell -p ~/halo ipc call shade toggle'"
