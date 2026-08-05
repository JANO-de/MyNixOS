{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    curl
    direnv
    cmake
    ninja
    pkg-config
    vscodium
    kdePackages.kate
    neovide
    godot
  ];
}
