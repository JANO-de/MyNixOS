{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/core
    ../../modules/hardware
    ../../modules/services
    ../../modules/desktop
    ../../modules/programs
  ];

  networking.hostName = "laptop";

  time.timeZone = "Europe/Madrid";

  i18n.defaultLocale = "es_ES.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "es_ES.UTF-8";
    LC_IDENTIFICATION = "es_ES.UTF-8";
    LC_MEASUREMENT = "es_ES.UTF-8";
    LC_MONETARY = "es_ES.UTF-8";
    LC_NAME = "es_ES.UTF-8";
    LC_NUMERIC = "es_ES.UTF-8";
    LC_PAPER = "es_ES.UTF-8";
    LC_TELEPHONE = "es_ES.UTF-8";
    LC_TIME = "es_ES.UTF-8";
  };

  console.keyMap = "es";

  # External NTFS drive "Elements" (Seagate). Mounted with ntfs-3g (FUSE), which
  # is safe for read/write on NTFS. "nofail" means boot won't block/stop when
  # the drive isn't plugged in; then just open /mnt/Elements to access it.
  fileSystems."/mnt/Elements" = {
    device = "/dev/disk/by-uuid/D6B6960AB695EB6F";
    fsType = "ntfs-3g";
    options = [ "nofail" "uid=1000" "gid=100" "umask=000" ];
  };

  # ntfs-3g provides the mount.ntfs-3g helper used by the mount above
  environment.systemPackages = with pkgs; [
    ntfs3g
  ];

  # Home Manager: per-user declarative configuration lives in ../../modules/home
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = { inherit inputs; theme = import ../../modules/theme.nix; };
    users.jano = import ../../modules/home/default.nix;
  };

  system.stateVersion = "26.05";
}
