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
  # Plasma 6 (Wayland): its built-in virtual keyboard arrived in 6.1, auto screen
  # rotation is fed through iio-sensor-proxy (hardware.sensor.iio below), and the
  # SDDM greeter is already themed for it. No GNOME, no heavy IDEs/office/gaming
  # runtimes.
  modules.desktop.niri.enable = false;
  modules.desktop.plasma.enable = true;
  modules.desktop.gnome.enable = false;
  # Themed login screen (catppuccin) owned by greeter.nix; SDDM is also what the
  # Plasma session is built against, so the greeter and the desktop agree.
  modules.desktop.displayManager = "sddm";
  # ...and the password field comes with an on-screen keyboard, so the greeter is
  # not a dead end on a touch-only tablet.
  modules.desktop.greeterOsK.enable = true;
  modules.programs.heavy.enable = false;
  modules.programs.gaming.enable = false;
  # The XAMPP workbench lives on the laptop (/opt/lampp); the tablet has none.
  modules.services.xampp.enable = false;

  # Power: longer battery life than the desktop, and the drives are old enough
  # to be worth watching.
  modules.services.powertop.enable = true;
  modules.services.smartd.enable = true;

  # Reading/scanning and poking around from a terminal.
  modules.programs.zathura.enable = true;
  modules.programs.qol.enable = true;

  # The bezel/ACPI power and volume keys are GNOME-handled by the modules above;
  # under Plasma they belong to powerdevil (System Settings > Power Management)
  # and kwin's global shortcuts, so those GNOME-only modules are off. The udev
  # ID_INPUT_KEYBOARD rule in modules/hardware/surface.nix still makes the
  # gpio-keys nodes visible to a Wayland compositor, and hardware/surface.nix
  # documents what happens with the power key.
  modules.desktop.powerButton.enable = false;
  modules.desktop.volumeKeys.enable = false;
  modules.desktop.idleLock.enable = false;

  # Accelerometer/gyro feed for auto screen rotation; Plasma reads it through
  # iio-sensor-proxy. Harmless without a sensor; enable Auto Rotate in System
  # Settings > Display and Monitor.
  hardware.sensor.iio.enable = true;

  # Qt virtual keyboard also served to the Plasma session, so a text field gets
  # an on-screen keyboard when no physical keyboard is attached (rendered by
  # Plasma 6.1+).
  environment.systemPackages = [
    pkgs.wl-clipboard
    pkgs.qt6.qtvirtualkeyboard
  ];

  # The Surface doubles as an extra monitor: moonlight-qt renders a sunshine
  # server's screen (laptop/desktop) fullscreen.
  modules.programs.moonlight.enable = true;

  # Deskflow keyboard/mouse sharing: the tablet can serve its Type Cover or
  # join a server. Pick one (Surface as client of the laptop/desktop):
  #   modules.programs.deskflow.role = "client";
  #   modules.programs.deskflow.serverAddress = "laptop";
  # or serve nothing at all (just keep the binaries):
  #   modules.programs.deskflow.role = "none";

  # Tablet: a real login screen, no autologin. SDDM themes the greeter
  # (catppuccin) and its Qt on-screen keyboard (greeterOsK) types the password,
  # so a lock screen is not a dead end on a touch-only tablet.
  # The screen still locks automatically on suspend/idle (Plasma's kscreenlocker).

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

  # Hibernate to the swapfile above: the resume device is the filesystem that
  # holds it, and the kernel/systemd finds the swap header on it. The 8 GB
  # swapfile is only usable for hibernate if the image is smaller than that,
  # which on 4 GB of RAM means a suspended session with a couple of apps open.
  # Verify a real hibernate/resume cycle before relying on it.
  boot.resumeDevice = "/dev/disk/by-label/NIXROOT";

  # Waydroid setup for surface
  virtualisation.waydroid.enable = true;
  virtualisation.waydroid.package = pkgs.waydroid-nftables;

  # Home Manager: per-user declarative configuration lives in ../../modules/home
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    # niriEnabled=false skips the niri wayland config; gnomeEnabled=false skips
    # the touch-first GNOME tweaks (the Surface now runs Plasma).
    extraSpecialArgs = {
      inherit inputs;
      theme = import ../../modules/theme.nix;
      niriEnabled = false;
      gnomeEnabled = false;
    };
    # users.jano merges the shared home config with tablet/pen extras: the pen
    # apps used to arrive via the GNOME home module, and are kept here so the
    # Plasma session still has them (iptsd feeds them pen pressure at the
    # kernel level).
    users.jano = lib.mkMerge [
      (import ../../modules/home/default.nix)
      {
        home.packages = [ pkgs.xournalpp pkgs.rnote ];
      }
    ];
  };

  system.stateVersion = "26.05";
}