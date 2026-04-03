{ inputs, pkgs, ... }:
{
  imports = [ inputs.ags.homeManagerModules.default ];

  programs.ags = {
    enable = true;
    configDir = ./parts/base/ags;

    extraPackages = with pkgs; [
      # Use the system attribute from the pkgs object passed to the module
      inputs.astal.packages.${system}.battery 
      fzf
    ];
  };
}