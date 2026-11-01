# halo-ipc: talk to the halo-test shell on the Surface (halo-ipc call shade toggle).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.halo-ipc;
in
{
  options.modules.scripts.halo-ipc.enable = lib.mkEnableOption "the halo-ipc command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
