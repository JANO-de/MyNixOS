{ pkgs, inputs, self, ... }: {
  imports = [
    "${self}/modules/home/apps.nix"
    "${self}/modules/home/niri.nix"
    "${self}/modules/home/shell.nix"
  ];

  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;
}
