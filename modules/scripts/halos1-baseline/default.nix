# halos1-baseline: battery baseline measurement (run on halos1, on battery).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.halos1-baseline;
in
{
  options.modules.scripts.halos1-baseline.enable = lib.mkEnableOption "the halos1-baseline command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
