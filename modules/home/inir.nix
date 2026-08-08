# modules/home/inir.nix
{ config, pkgs, lib, ... }:

let
  inirSrc = pkgs.fetchFromGitHub {
    owner = "snowarch";
    repo = "inir";
    rev = "v2.29.0";  # or latest commit hash
    hash = "sha256-...";  # generate with nix prefetch github
  };

  inirPython = pkgs.python3.withPackages (ps: with ps; [
    pillow
    loguru
    materialyoucolor
    tqdm
    click
    numpy
    pygobject3
    opencv4
  ]);
in
{
  home.packages = with pkgs; [
    quickshell
    inirPython
    # iNiR dependencies
    grim
    slurp
    cliphist
    wl-clipboard
    matugen
    wlsunset
    libnotify
    material-symbols
    nerd-fonts.jetbrains-mono
  ];

  xdg.configFile."quickshell/inir".source = inirSrc;
  xdg.configFile."quickshell/inir".recursive = true;
}