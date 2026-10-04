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

  networking.hostName = "desktop";

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

  # Freshly formatted internal data drives (ext4, wiped in place of the old
  # NTFS/btrfs layouts). "nofail" keeps boot snappy even if a drive is missing,
  # "noatime" avoids the write traffic a desktop does not need.
  fileSystems."/mnt/data" = {
    device = "/dev/disk/by-uuid/f6a19317-f36e-4a3f-8934-423b2e3d8ed4";
    fsType = "ext4";
    options = [ "nofail" "noatime" ];
  };

  fileSystems."/mnt/ssd" = {
    device = "/dev/disk/by-uuid/949f3a95-eae7-4068-a57a-ff0d695142e1";
    fsType = "ext4";
    options = [ "nofail" "noatime" ];
  };

  # ntfs-3g provides the mount.ntfs-3g helper used by the mount above
  environment.systemPackages = with pkgs; [
    ntfs3g
  ];

  # The Surface acts as an extra monitor via this sunshine server + moonlight
  # on the tablet. NB: capture on this host runs on the NVIDIA/Intel hybrid
  # GPU under Wayland, so test the KMS backend if streaming is flaky.
  modules.services.sunshine.enable = true;

  # SDDM picks its session from `defaultSession`, and nixpkgs' sddm module
  # defaults that to plasma. Left alone, the greeter therefore starts Plasma,
  # not niri -- logging in shows nothing useful on a machine that actually runs
  # niri, and it looks like the login itself failed ("Started Session 2 of
  # User jano" then a blank screen, because the session that came up was never
  # the one wanted).
  services.displayManager.defaultSession = "niri";

  # Deskflow keyboard/mouse sharing: this machine may serve or join another.
  # Pick one: modules.programs.deskflow.role = "server";
  #         modules.programs.deskflow.role = "client"; modules.programs.deskflow.serverAddress = "laptop";

  # Home Manager: per-user declarative configuration lives in ../../modules/home
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    # `tablet` toggles the touch-only parts of the niri config (see
    # modules/home/niri.nix). Not a tablet: false.
    # `niriEnabled`/`gnomeEnabled` select which home modules apply (the surface
    # runs GNOME: niri=false, gnome=true).
    extraSpecialArgs = {
      inherit inputs;
      theme = import ../../modules/theme.nix;
      tablet = false;
      niriEnabled = true;
      gnomeEnabled = false;
    };
    users.jano = import ../../modules/home/default.nix;
  };

  system.stateVersion = "26.05";
}
