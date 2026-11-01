# halos1-clean: drop old Surface generations and rewrite the boot menu.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.halos1-clean;
in
{
  options.modules.scripts.halos1-clean.enable = lib.mkEnableOption "the halos1-clean command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
