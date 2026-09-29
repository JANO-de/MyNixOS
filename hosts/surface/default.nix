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

  # Tablet: no password at the login screen — GDM autologin into the GNOME
  # session, which does have an on-screen keyboard if a password is ever needed
  # again. The screen locks on suspend.
  services.displayManager.autoLogin = {
    enable = true;
    user = "jano";
  };

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