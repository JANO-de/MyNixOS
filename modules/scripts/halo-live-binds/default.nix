# halo-live-binds: reset Hyprland binds and add the top-edge shade bind on the Surface.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.halo-live-binds;
in
{
  options.modules.scripts.halo-live-binds.enable = lib.mkEnableOption "the halo-live-binds command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
