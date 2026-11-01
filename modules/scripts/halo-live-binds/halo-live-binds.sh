#!/usr/bin/env bash
# Resets binds (hyprctl reload) and adds the top-edge shade bind, pointed at the halo-test shell.
set -euo pipefail
IP="${HALO_IP:-192.168.0.115}"
SSHO=(-o ControlMaster=auto -o "ControlPath=$HOME/.ssh/cm-%r@%h" -o ControlPersist=10m)
ssh "${SSHO[@]}" "jano@$IP" 'bash -s' <<'REMOTE'
export XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-1
export PATH="/run/current-system/sw/bin:$PATH"
export HYPRLAND_INSTANCE_SIGNATURE=$(ls /run/user/1000/hypr | grep -v chronos-shell | head -1)
qs=$(ls -d /nix/store/*-quickshell-0.3.0/bin/quickshell | tail -1)
hyprctl reload   # drops earlier live binds so the gesture cannot fire twice
sleep 1
hyprctl eval "hl.plugin.hyprgrass.bind { pattern = { kind = 'edge', origin = 'up', direction = 'down' }, action = hl.dsp.exec_cmd('$qs -p /home/jano/halo ipc call shade open') }"
hyprctl configerrors
REMOTE
