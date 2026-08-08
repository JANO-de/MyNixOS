{ config, pkgs, inputs, ... }:

{
  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "26.05";

  imports = [
    ./niri.nix
    ./theme.nix
    ./end4-pc.nix
  ];
}
