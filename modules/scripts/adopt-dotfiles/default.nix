# adopt-dotfiles: first-time import of ~/.config/{hypr,hyprmon,illogical-impulse,matugen} into hosts/<host>/dotfiles (run BEFORE the first rebuild with dotfiles.enable).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.scripts.adopt-dotfiles;
in
{
  options.modules.scripts.adopt-dotfiles.enable = lib.mkEnableOption "the adopt-dotfiles command";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      (import ./package.nix {
        inherit pkgs;
        repoPath = config.modules.scripts.repoPath;
      })
    ];
  };
}
