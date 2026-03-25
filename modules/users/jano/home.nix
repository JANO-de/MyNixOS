{ pkgs, inputs, self, ... }: {
  imports = [
    "${self}/parts/home/apps.nix"
  ];

  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}