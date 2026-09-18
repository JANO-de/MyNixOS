{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    alacritty
    starship
    eza
    bat
    ripgrep
    fd
    procs
    zoxide
    z-lua
    fastfetch
  ];
}
