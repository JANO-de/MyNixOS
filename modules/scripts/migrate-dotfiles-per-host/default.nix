# migrate-dotfiles-per-host: move the legacy flat dotfiles/ layout to hosts/<host>/dotfiles.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.migrate-dotfiles-per-host;
in
{
  options.modules.scripts.migrate-dotfiles-per-host.enable = lib.mkEnableOption "the migrate-dotfiles-per-host command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
