# Keep app-written configs inside the flake repo instead of loose files in ~/.config.
#
# ~/.config/{hypr,hyprmon,illogical-impulse,matugen} become symlinks to
# <repoPath>/dotfiles/<host>/<name>. One folder per host, because some files are machine-specific
# (hyprmon.lua monitor layout, ii config.json, per-GPU settings).
# Hyprland, hyprmon (hyprmon.lua, profiles) and the ii shell (illogical-impulse/config.json, matugen
# output) then write straight into the repo, so `git diff` shows every change. The links point at
# the live checkout (not the Nix store), so edits apply without a rebuild.
#
# First time on a host: run scripts/adopt-dotfiles.sh --host <host> BEFORE the rebuild.
{ config, lib, inputs, ... }:

let
  cfg = config.modules.desktop.dotfiles;
  hmDag = inputs.home-manager.lib.hm.dag;
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
    host = lib.mkOption {
      type = lib.types.str;
      default = config.networking.hostName;
      defaultText = lib.literalExpression "config.networking.hostName";
      description = "Folder name under dotfiles/ used by this machine.";
    };
    dir = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.repoPath}/dotfiles/${cfg.host}";
      description = ''
        Directory the configs live in (also used by ii.nix). Override only to keep a host on the
        old flat layout (<repo>/dotfiles) until it is migrated with scripts/migrate-dotfiles-per-host.sh.
      '';
    };
    quickshell = lib.mkEnableOption "also link ~/.config/quickshell/ii (the ii QML tree, ~52 MB; off by default, ii settings live in illogical-impulse/config.json)";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.jano = { config, ... }: {
      # The link targets must exist before home-manager creates the links.
      home.activation.dotfilesDirs = hmDag.entryBefore [ "linkGeneration" ] ''
        run mkdir -p ${lib.concatMapStringsSep " " (n: "\"${cfg.dir}/${n}\"") names}
      '';

      xdg.configFile = {
        "hypr".source = config.lib.file.mkOutOfStoreSymlink "${cfg.dir}/hypr";
        "hyprmon".source = config.lib.file.mkOutOfStoreSymlink "${cfg.dir}/hyprmon";
        "illogical-impulse".source = config.lib.file.mkOutOfStoreSymlink "${cfg.dir}/illogical-impulse";
        "matugen".source = config.lib.file.mkOutOfStoreSymlink "${cfg.dir}/matugen";
      } // lib.optionalAttrs cfg.quickshell {
        "quickshell/ii".source = config.lib.file.mkOutOfStoreSymlink "${cfg.dir}/quickshell-ii";
      };
    };
  };
}
