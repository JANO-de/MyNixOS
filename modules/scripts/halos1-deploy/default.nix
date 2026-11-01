# halos1-deploy: rebuild the Surface from this machine (nixos-rebuild boot).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.halos1-deploy;
in
{
  options.modules.scripts.halos1-deploy.enable = lib.mkEnableOption "the halos1-deploy command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
