#!/usr/bin/env bash
# Adapted from temp/inir-nixos/scripts/verify-setup.sh for this flake.
# Read-only sanity check for the declarative (NixOS-module) iNiR install.
# Never modifies anything.

set -uo pipefail

FAILURES=0

ok() {
    echo "  ok: $1"
}

fail() {
    echo "  FAIL: $1"
    FAILURES=$((FAILURES + 1))
}

warn() {
    echo "  warn: $1"
}

check_command() {
    local cmd="$1"
    local name="${2:-$1}"

    if command -v "$cmd" >/dev/null 2>&1; then
        ok "$name found"
    else
        fail "$name not found (is programs.inir.enable set?)"
    fi
}

echo "-- Checking iNiR + niri + NixOS setup --"

check_command niri "niri"
check_command inir "inir"
check_command python3 "python3"
check_command jq "jq"

# inotifywait is only injected into the niri-sync-colors.service PATH (not the
# interactive user PATH), so resolve it from the running unit's environment.
if command -v inotifywait >/dev/null 2>&1 ||
   systemctl --user show niri-sync-colors.service -p Environment 2>/dev/null |
        grep -q inotify-tools; then
    ok "inotifywait found"
else
    fail "inotifywait not found (is programs.inir.enable set?)"
fi

systemctl --user list-units --type=service 2>/dev/null | grep -q "inir.service" \
    && ok "inir.service unit present" \
    || fail "inir.service unit missing"

if systemctl --user is-active --quiet inir.service; then
    ok "inir.service is running"
else
    warn "inir.service is not running"
fi

if systemctl --user is-enabled --quiet niri-sync-colors.service 2>/dev/null; then
    ok "niri-sync-colors.service is enabled"
else
    warn "niri-sync-colors.service is not enabled"
fi

if systemctl --user is-active --quiet niri-sync-colors.service; then
    ok "niri-sync-colors.service is running"
else
    warn "niri-sync-colors.service is not running"
fi

if [[ -f "$HOME/.config/niri/config.kdl" ]]; then
    ok "niri config.kdl exists"
else
    fail "~/.config/niri/config.kdl missing"
fi

if niri validate --config "$HOME/.config/niri/config.kdl" 2>/dev/null; then
    ok "niri config validates"
else
    warn "could not validate niri config (niri validate may need a compositor)"
fi

# Resolve niri-config.py from the running service's NIRI_CONFIG_PY env var (it
# lives in the inir package store path in a declarative install, not in
# ~/.config/quickshell).
NIRI_CONFIG_PY="$(systemctl --user show niri-sync-colors.service -p Environment 2>/dev/null | tr ' ' '\n' | sed -n 's/^NIRI_CONFIG_PY=//p')"
if [[ -n "$NIRI_CONFIG_PY" && -f "$NIRI_CONFIG_PY" ]]; then
    ok "iNiR niri-config.py exists"
else
    warn "iNiR niri-config.py not found (run the shell once to generate ~/.config/quickshell)"
fi

if systemctl --user is-enabled --quiet check-config-updates.timer 2>/dev/null; then
    ok "update notification timer is enabled"
else
    warn "check-config-updates.timer not enabled (opt-in)"
fi

if systemctl --user is-enabled --quiet auto-update.timer 2>/dev/null &&
   [[ "$(systemctl --user is-enabled auto-update.timer 2>/dev/null)" == "enabled" ]]; then
    ok "auto-update timer is enabled"
else
    warn "auto-update.timer not enabled (opt-in: systemctl --user enable --now auto-update.timer)"
fi

echo "-- Done --"

if (( FAILURES > 0 )); then
    echo "verification failed: $FAILURES check(s) failed."
    exit 1
fi

echo "verification passed."
exit 0