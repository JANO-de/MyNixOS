{ config, pkgs, inputs, ... }:

{
  home.username = "jano";
  home.homeDirectory = "/home/jano";
  home.stateVersion = "26.05";

  imports = [
    inputs.noctalia.homeModules.default
    ./niri.nix
    ./theme.nix
  ];

  programs.noctalia = {
    enable = true;
    settings = {
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };
      # Keep apps launched from Noctalia alive across shell restarts
      shell.launch_apps_as_systemd_services = true;
    };
  };
}
