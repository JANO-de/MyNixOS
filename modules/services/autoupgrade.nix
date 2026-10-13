{ config, pkgs, ... }:
{
  system.autoUpgrade = {
    enable = false;
    flake = "github.com:JANO-de/MyNixOS.git"; # wherever this flake.nix is pushed
    flags = [ "--update-input" "opencode-flake" ];
    dates = "daily";
    randomizedDelaySec = "45min";
  };
}