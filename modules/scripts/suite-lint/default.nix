# suite-lint: lint the Halo suite QML apps.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.suite-lint;
in
{
  options.modules.scripts.suite-lint.enable = lib.mkEnableOption "the suite-lint command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
