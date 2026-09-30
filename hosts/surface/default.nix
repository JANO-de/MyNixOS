{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../modules/core
    ../../modules/hardware
    # nixos-hardware's Surface Pro (Intel) support: linux-surface patched
    # kernel, IPTS touch/pen (iptsd), Marvell mwifiex wifi firmware, thermald,
    # surface-control, S0ix sleep.
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel
    # Surface Pro 5 specifics not covered by the module above.
    ../../modules/hardware/surface.nix
    ../../modules/services
    ../../modules/desktop
    ../../modules/programs
  ];

  # The SP5 only has Intel HD 620 graphics, no NVIDIA GPU.
  hardware.nvidia.enable = false;

  # 4 GB of RAM / 128 GB disk: keep the closure small and the tablet lean.
  # GNOME + Wayland instead of niri: built-in on-screen keyboard, auto screen
  # rotation (iio-sensor-proxy), HiDPI scaling and touch gestures straight
  # from the settings. No Plasma/KDE, no heavy IDEs/office/gaming runtimes.
  modules.desktop.niri.enable = false;
  modules.desktop.plasma.enable = false;
  modules.desktop.gnome.enable = true;
  modules.programs.heavy.enable = false;
  modules.programs.gaming.enable = false;
  # The XAMPP workbench lives on the laptop (/opt/lampp); the tablet has none.
  modules.services.xampp.enable = false;

  # Cheapest battery wins on a Skylake tablet: PowerTOP autotune at boot and
  # smartd keeping an eye on the 2016-era SSD.
  modules.services.powertop.enable = true;
  services.smartd.enable = true;

  # The Surface doubles as an extra monitor: moonlight-qt renders a sunshine
  # server's screen (laptop/desktop) fullscreen.
  modules.programs.moonlight.enable = true;

  # Deskflow keyboard/mouse sharing: the tablet can serve its Type Cover or
  # join a server. Pick one (Surface as client of the laptop/desktop):
  #   modules.programs.deskflow.role = "client";
  #   modules.programs.deskflow.serverAddress = "laptop";
  # or serve nothing at all (just keep the binaries):
  #   modules.programs.deskflow.role = "none";

  # Login screen: GDM, no autologin anymore. Pretty it up with the theme's
  # catppuccin-mocha wallpaper (greeter renders org.gnome.desktop.background).
  programs.dconf.profiles.gdm.databases = [
    {
      settings."org/gnome/desktop/background" = {
        picture-uri = "file://${pkgs.nixos-artwork.wallpapers.catppuccin-mocha.gnomeFilePath}";
        picture-uri-dark = "file://${pkgs.nixos-artwork.wallpapers.catppuccin-mocha.gnomeFilePath}";
      };
    }
  ];

  # Volume rocker: the SP5 buttons report plain VolUp/VolDown keycodes (they
  # are "Sideband GPIO" events), so GNOME gets the events and routes them via
  # gsd -> pipewire. If they still do nothing, the usual culprits are (a) no
  # default sink (see the wireplumber note in modules/services/audio.nix) or
  # (b) the rocker reporting as unknown scancodes — then run `keyd monitor`
  # while pressing it and enable a mapping like:
  #   services.keyd.enable = true;
  #   services.keyd.keyboards.surface-rocker = { ids = [ "...:...:..." ]; settings = { pageup = "volumeup"; pagedown = "volumedown"; }; };

  # Hibernate (in the GNOME power dialog) needs a resume_from-swapfile entry:
  # read the current volume key:  sudo filefrag -v /swapfile  (first row, 4th
  # column) and the root UUID (blkid), then uncomment:
  #   boot.resumeDevice = "/dev/disk/by-uuid/XXXX";
  #   boot.kernelParams = [ "resume_offset=YYYY" ];
  # Then GDM's power dialog gains a Hibernate button next to Suspend.

  networking.hostName = "surface";

  # THROWAWAY passwords so first boot is reachable (tty + SSH); the real ones
  # are set imperatively afterwards with `passwd jano` / `passwd root`.
  users.users.jano.initialPassword = "bde92496e9dbd256";
  users.users.root.initialPassword = "bde92496e9dbd256";

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

  # SP5 screen-tearing fix (same as the installer live config).
  boot.kernelParams = [ "i915.enable_psr=0" ];

  # No hardware-configuration.nix on purpose: the filesystem layout is declared
  # by label so the exact disk/UUIDs of this particular unit do not have to be
  # committed. Install with:
  #   mkfs.fat -F32 -n NIXBOOT <p1>; mkfs.ext4 -L NIXROOT <p2>
  # i.e. 512MB FAT32 EFI System Partition, rest ext4.
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/NIXBOOT";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/NIXROOT";
    fsType = "ext4";
  };

  # 4GB of RAM: keep the zram ceiling from modules/core below half of physical
  # memory so a swap-heavy workload cannot eat the whole system. On top of it,
  # an 8GB swapfile gives suspend/restore and GNOME (shell + daemons are a bit
  # hungrier than niri) room to breathe (NixOS creates the swapfile on first
  # activation).
  zramSwap = {
    memoryPercent = lib.mkForce 50;
    memoryMax = lib.mkForce 4294967296; # 4 GiB
  };

  swapDevices = [
    { device = "/swapfile"; size = 8192; }
  ];

  # Waydroid setup for surface
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;
  environment.systemPackages = [ pkgs.wl-clipboard ];

  # Home Manager: per-user declarative configuration lives in ../../modules/home
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    # niriEnabled=false skips the niri wayland config (surface runs GNOME);
    # gnomeEnabled=true pulls the touch-first GNOME tweaks.
    extraSpecialArgs = {
      inherit inputs;
      theme = import ../../modules/theme.nix;
      niriEnabled = false;
      gnomeEnabled = true;
    };
    users.jano = import ../../modules/home/default.nix;
  };

  system.stateVersion = "26.05";
}