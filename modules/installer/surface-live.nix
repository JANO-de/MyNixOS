# Additions to the stock GNOME installation image (nixosConfigurations.installer).
#
# Why: the upstream ISO cannot drive the Surface Pro 5's touchscreen/pen (Intel
# IPTS controller) and ships no firmware for its Marvell 88W8997 Wi-Fi, so the
# live session would come up with neither touch nor network — and nixos-install
# --flake needs to reach GitHub. The nixos-hardware Surface module (patched
# kernel, iptsd, redistributable firmware, thermald) is imported directly in
# flake.nix to fix both; this file only carries small live-session tweaks.
{ lib, ... }:

{
  # Belt and braces for the early i915 modeset: some Surface panels come up
  # black with Panel Self Refresh enabled on Kaby Lake. Harmless if PSR is not
  # the culprit, and applies to the ISO's kernel cmdline only.
  boot.kernelParams = [ "i915.enable_psr=0" ];
}