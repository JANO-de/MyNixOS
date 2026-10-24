#!/usr/bin/env bash
# Open item 6: a stray `bootctl set-oneshot` was run on the desktop. Check and clear it.
set -euo pipefail
sudo bootctl status | grep -i oneshot || echo "no oneshot set"
sudo bootctl set-oneshot "" 2>/dev/null && echo "oneshot cleared" || true
