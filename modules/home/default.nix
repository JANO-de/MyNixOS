{ config, pkgs, inputs, lib, niriEnabled, gnomeEnabled, ... }:

{
  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "26.05";

  imports = [
    ./alacritty.nix
    ./theme.nix
  ]
  # The niri wayland config only matters where niri is the session (hosts pass
  # niriEnabled=false, e.g. the GNOME Surface).
  ++ lib.optional niriEnabled ./niri.nix
  # Tablet / touch-first GNOME tweaks (Surface). 
  ++ lib.optional gnomeEnabled ./gnome.nix;

  home.packages = [
    pkgs.jq
  ];
}
