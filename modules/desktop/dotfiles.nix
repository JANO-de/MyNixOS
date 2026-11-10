# Keep app-written configs inside the flake repo instead of loose files in ~/.config.
#
# ~/.config/<name> becomes a symlink to <repoPath>/hosts/<host>/dotfiles/<name> for every
# name in `names`. One folder per host, because some files are machine-specific.
# The links point at the live checkout (not the Nix store), so edits apply without a rebuild.
# `names` lists the app configs linked from the repo; add niri here once its config is tracked.
{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.desktop.dotfiles;
  hmDag = inputs.home-manager.lib.hm.dag;
  names = [ "kitty" "mango" "niri" "rofi" ];
in
{
  options.modules.desktop.dotfiles = {
    enable = lib.mkEnableOption "app configs stored in the flake repo via symlinks";
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
      default = "${cfg.repoPath}/hosts/${cfg.host}/dotfiles";
      description = "Directory the configs live in.";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.jano =
      { config, ... }:
      {
        home.activation.dotfilesDirs = lib.mkIf (names != [ ]) (
          hmDag.entryBefore [ "linkGeneration" ] ''
            run mkdir -p ${lib.concatMapStringsSep " " (n: "\"${cfg.dir}/${n}\"") names}
          ''
        );
        xdg.configFile = lib.genAttrs names (n: {
          source = config.lib.file.mkOutOfStoreSymlink "${cfg.dir}/${n}";
        });
      };
  };
}
