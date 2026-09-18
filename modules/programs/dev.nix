{ config, pkgs, lib, inputs, ... }:

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
    qt6.qt5compat
    pkgs.gowall
    btop
    qbittorrent
    nodejs_22
    inputs.opencode-flake.packages.${pkgs.system}.opencode-avx

    # Java
    jdk25
    android-studio
    eclipses.eclipse-java
    jetbrains.idea

    # iNiR Dependencies
    kdePackages.syntax-highlighting
    kdePackages.kirigami
    kdePackages.kdialog
    quickshell
    wl-clipboard
    cliphist
    wireplumber
    grim
    slurp
    python314Packages.materialyoucolor
    kdePackages.plasma-browser-integration
    kdePackages.plasma-integration
    darkly

    # DAW (Music)
    ardour
  ];
}
