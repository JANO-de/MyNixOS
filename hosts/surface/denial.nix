# Denial on the Surface Pro 5, using the Nix packaging published with the
# denial-arm64-builder flake (a copy of upstream's nix/ dir, pinned to Denial
# v0.5.1, exposes nixosModules.default -> programs.denial.enable).
# UNTESTED: no Nix/network in the authoring sandbox.
#
# flake.nix additions:
#   inputs.denial.url = "github:mumuxiao722/denial-arm64-builder";
#   (add `denial` to the outputs argument list; it is already passed via `inputs`)
# mkHost modules list: nothing else needed, this file imports the module.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [ inputs.denial.nixosModules.default ];

  programs.denial.enable = true;           # adds the "Denial" SDDM session; Plasma stays default

  # Upstream binary cache (x86-64). Without it Nix builds the custom Flutter
  # engine from source, which will not fit on 8 GB RAM / 128 GB disk.
  nix.settings.substituters = [ "https://denial.cachix.org" ];
  # trusted-public-keys: copy the key from https://denial.cachix.org
  # (not verified here, do not guess it).

  security.rtkit.enable = true;
  hardware.graphics.enable = true;         # Intel HD 620
  # If rendering glitches: DENIA_FLUTTER_RENDERER=skia (documented override).
}
