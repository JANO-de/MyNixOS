# halos1-reboot: reboot the Surface over SSH.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.halos1-reboot;
in
{
  options.modules.scripts.halos1-reboot.enable = lib.mkEnableOption "the halos1-reboot command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
