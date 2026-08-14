{ config, pkgs, lib, ... }:

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
    quickshell
    kdePackages.kirigami
    qt6.qt5compat
    pkgs.gowall
    btop
    qbittorrent
    opencode

    # DAW (Music)
    ardour
  ];
}
