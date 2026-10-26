#!/usr/bin/env bash
# Reboot the Surface (ssh -t is required so sudo can ask for the password).
set -euo pipefail
IP="${1:-192.168.0.115}"
exec ssh -t "jano@$IP" sudo reboot
