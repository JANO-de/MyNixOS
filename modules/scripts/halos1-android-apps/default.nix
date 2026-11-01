# halos1-android-apps: install F-Droid, Aurora Store and microG into Droidloom on halos1.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.halos1-android-apps;
in
{
  options.modules.scripts.halos1-android-apps.enable = lib.mkEnableOption "the halos1-android-apps command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
