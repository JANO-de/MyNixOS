# `niriEnabled` comes from the host's `specialArgs` (flake.nix); every host
# passes it explicitly (no default) so the module-system arg probe can't
# recurse. The surface host passes niriEnabled=false — that keeps the inir
# flake module (lightdm + quickshell niri shell) off a Plasma tablet. Keep it in
# sync with the `modules.desktop.niri.enable` option used inside niri.nix.
{ lib, niriEnabled, ... }:

{
  imports = [
    ./options.nix
    ./awww.nix
    ./greeter.nix
    ./plasma.nix
    ./niri.nix
    ./gnome.nix
    ./power-button.nix
    ./volume-keys.nix
    ./idle-lock.nix
  ] ++ lib.optional niriEnabled ./shell;
}