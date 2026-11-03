# Spotify through Spicetify (Catppuccin Mocha, Marketplace). The spicetify NixOS module is always
# imported (it only declares options); nothing is installed until modules.programs.spotify.enable.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.programs.spotify;
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in
{
  imports = [ inputs.spicetify-nix.nixosModules.default ];

  options.modules.programs.spotify.enable = lib.mkEnableOption "Spotify with Spicetify";

  config = lib.mkIf cfg.enable {
    programs.spicetify = {
      enable = true;
      theme = spicePkgs.themes.catppuccin;
      colorScheme = "mocha";

      enabledCustomApps = with spicePkgs.apps; [
        marketplace
      ];
    };
  };
}
