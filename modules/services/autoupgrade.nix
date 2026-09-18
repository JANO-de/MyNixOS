{ config, pkgs, ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:youwen5-placeholder/your-dotfiles-repo"; # wherever this flake.nix is pushed
    flags = [ "--update-input" "opencode-flake" ];
    dates = "daily";
    randomizedDelaySec = "45min";
  };
}