{ pkgs, inputs, ... }: {
  imports = [
    ../../modules/home/apps.nix
    ../../modules/home/niri.nix
    ../../modules/home/shell.nix
  ];

  home.username = "jano";
  home.homeDirectory = "/home/jano";

  # This is the "version" of Home Manager. Keep it at what it was
  # when you first installed to avoid breaking changes.
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
