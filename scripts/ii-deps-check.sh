#!/usr/bin/env bash
# ii dependency audit. Usage: scripts/ii-deps-check.sh
# Checks binaries, Rust helpers, python modules, fonts, versions. Prints only problems.
QS="${QS:-$HOME/.config/quickshell/ii}"
PY="${ILLOGICAL_IMPULSE_VIRTUAL_ENV:-}/bin/python3"; [ -x "$PY" ] || PY=python3
miss=0
bad(){ echo "MISSING $1: $2"; miss=1; }

echo "== required binaries =="
for b in hyprctl qs matugen wpctl pactl nmcli bluetoothctl playerctl brightnessctl ddcutil \
  notify-send wl-copy wl-paste grim slurp hyprpicker hyprlock hypridle hyprsunset hyprshot hyprshade \
  cliphist ydotool magick identify ffmpeg ffprobe yt-dlp gsettings gio gjs xdg-open xdg-mime gtk-launch \
  cava trans fc-list file git curl jq rg systemctl loginctl timedatectl busctl rfkill pkill pgrep pidof killall \
  upower swappy tesseract wf-recorder hyprmon cargo rustc; do
  command -v "$b" >/dev/null || bad bin "$b"
done
echo "== optional binaries =="
for b in nautilus blueman-manager scrcpy adb khal vdirsyncer warp-cli tailscale nordvpn protonvpn \
  docker voxtype mpvpaper upscayl avahi-browse fprintd-list linux-wallpaperengine; do
  command -v "$b" >/dev/null || echo "optional-missing: $b"
done

echo "== python modules =="
"$PY" - <<'PYEOF'
import importlib
for m in "gi PIL cv2 numpy materialyoucolor dbus evdev psutil requests scipy click loguru tqdm".split():
    try: importlib.import_module(m)
    except Exception as e: print("MISSING py:", m, "-", e)
for m in "google.oauth2 obsws_python".split():
    try: importlib.import_module(m)
    except Exception: print("optional-missing py:", m)
PYEOF

echo "== rust helpers =="
[ -x "$QS/scripts/rust-helpers.sh" ] && "$QS/scripts/rust-helpers.sh" status | awk '$2!="ok"{print "RUST " $0}'

echo "== fonts =="
for f in "Google Sans Flex" "JetBrains Mono" "JetBrainsMono Nerd Font" "Material Symbols"; do
  fc-list | grep -qi "$f" || bad font "$f"
done

echo "== versions (need hyprland>=0.56.1 matugen>=4.1.0 quickshell>=0.3.0) =="
hyprctl version 2>/dev/null | head -1; matugen --version; qs --version
echo "== groups =="; id -nG | grep -qw i2c || bad group i2c
echo "== service =="; systemctl --user is-active ii >/dev/null || echo "ii.service not active"
echo "== qml modules (startup log) =="
journalctl --user -u ii -b --no-pager 2>/dev/null | grep -iE 'is not installed|module .* not|cannot find|failed to load' | sort -u | tail -15
exit $miss
