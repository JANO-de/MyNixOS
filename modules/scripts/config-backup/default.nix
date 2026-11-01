# config-backup: back up / restore the mutable ii, Hyprland and hyprmon configs.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.config-backup;
in
{
  options.modules.scripts.config-backup.enable = lib.mkEnableOption "the config-backup command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
