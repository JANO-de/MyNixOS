# Helper commands (one folder per script). Off until a host enables a command or the bundle:
#   modules.scripts.all = true;   # every command, on the dev hosts
#   modules.scripts.config-backup.enable = true;   # a single one
# The commands run from the repo checkout at modules.scripts.repoPath.
{ config, lib, ... }:
{
  options.modules.scripts = {
    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/jano/Proyectos/MyNixOS";
      description = "Absolute path of this repo's checkout on the machine (the commands cd there).";
    };
    all = lib.mkEnableOption "every helper command in modules/scripts";
  };

  imports = [
    ./adopt-dotfiles
    ./config-backup
    ./migrate-dotfiles-per-host
  ];

  config = lib.mkIf config.modules.scripts.all {
    modules.scripts = {
      adopt-dotfiles.enable = lib.mkDefault true;
      config-backup.enable = lib.mkDefault true;
      migrate-dotfiles-per-host.enable = lib.mkDefault true;
    };
  };
}
