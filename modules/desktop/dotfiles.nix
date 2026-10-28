# Keep app-written configs inside the flake repo instead of loose files in ~/.config.
#
# ~/.config/{hypr,hyprmon,illogical-impulse,matugen} become symlinks to <repoPath>/dotfiles/<name>.
# Hyprland, hyprmon (hyprmon.lua, profiles) and the ii shell (illogical-impulse/config.json, matugen
# output) then write straight into the repo, so `git diff` shows every change. The links point at
# the live checkout (not the Nix store), so edits apply without a rebuild.
#
# First time: run scripts/adopt-dotfiles.sh BEFORE the rebuild (moves your current config into the repo).
{ config, lib, inputs, ... }:

let
  cfg = config.modules.desktop.dotfiles;
  hmDag = inputs.home-manager.lib.hm.dag;
  dir = "${cfg.repoPath}/dotfiles";
  names = [ "hypr" "hyprmon" "illogical-impulse" "matugen" ]
    ++ lib.optional cfg.quickshell "quickshell-ii";
in
{
  options.modules.desktop.dotfiles = {
    enable = lib.mkEnableOption "app configs (hypr, hyprmon, ii, matugen) stored in the flake repo via symlinks";
    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/jano/Proyectos/MyNixOS";
      description = "Absolute path of this repo's checkout on the machine (the links point here).";
    };
    quickshell = lib.mkEnableOption "also link ~/.config/quickshell/ii (the ii QML tree, ~52 MB; off by default, ii settings live in illogical-impulse/config.json)";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.jano = { config, ... }: {
      # The link targets must exist before home-manager creates the links.
      home.activation.dotfilesDirs = hmDag.entryBefore [ "linkGeneration" ] ''
        run mkdir -p ${lib.concatMapStringsSep " " (n: "\"${dir}/${n}\"") names}
      '';

      xdg.configFile = {
        "hypr".source = config.lib.file.mkOutOfStoreSymlink "${dir}/hypr";
        "hyprmon".source = config.lib.file.mkOutOfStoreSymlink "${dir}/hyprmon";
        "illogical-impulse".source = config.lib.file.mkOutOfStoreSymlink "${dir}/illogical-impulse";
        "matugen".source = config.lib.file.mkOutOfStoreSymlink "${dir}/matugen";
      } // lib.optionalAttrs cfg.quickshell {
        "quickshell/ii".source = config.lib.file.mkOutOfStoreSymlink "${dir}/quickshell-ii";
      };
    };
  };
}
