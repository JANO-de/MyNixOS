# Helper commands (one folder per script). Off until a host enables a command or the bundle:
#   modules.scripts.all = true;   # every command, on the dev hosts
#   modules.scripts.halo-dev.enable = true;   # a single one
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
    ./halo-dev
    ./halo-ipc
    ./halo-live-binds
    ./halos1-android-apps
    ./halos1-baseline
    ./halos1-clean
    ./halos1-deploy
    ./halos1-reboot
    ./migrate-dotfiles-per-host
    ./suite-lint
  ];

  config = lib.mkIf config.modules.scripts.all {
    modules.scripts = {
      adopt-dotfiles.enable = lib.mkDefault true;
      config-backup.enable = lib.mkDefault true;
      halo-dev.enable = lib.mkDefault true;
      halo-ipc.enable = lib.mkDefault true;
      halo-live-binds.enable = lib.mkDefault true;
      halos1-android-apps.enable = lib.mkDefault true;
      halos1-baseline.enable = lib.mkDefault true;
      halos1-clean.enable = lib.mkDefault true;
      halos1-deploy.enable = lib.mkDefault true;
      halos1-reboot.enable = lib.mkDefault true;
      migrate-dotfiles-per-host.enable = lib.mkDefault true;
      suite-lint.enable = lib.mkDefault true;
    };
  };
}
