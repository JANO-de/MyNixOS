# halo-dev: hot-reload loop for the Halo shell on the Surface (no rebuild, no reboot).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.halo-dev;
in
{
  options.modules.scripts.halo-dev.enable = lib.mkEnableOption "the halo-dev command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
