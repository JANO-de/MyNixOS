{ pkgs, inputs, self, ... }: {
  imports = [
    ../../modules/home/apps.nix
    ../../modules/home/niri.nix
    ../../modules/home/shell.nix
  ];

  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
