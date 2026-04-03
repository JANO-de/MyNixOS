{ inputs, pkgs, ... }:
{
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;
    configDir = ./parts/base/ags;

    extraPackages = with pkgs; [
      # Reference the system via stdenv to avoid the circular pkgs dependency
      inputs.astal.packages.${pkgs.stdenv.hostPlatform.system}.battery
      fzf
    ];
  };
}