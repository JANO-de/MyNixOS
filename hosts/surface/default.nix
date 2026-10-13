# Microsoft Surface Pro 5 tablet — lean Plasma 6 (Wayland) host.
# Uses the LEAN program set (modules/programs/lean.nix), not the full one.
#
#   default.nix       identity, memory/swap, services (this file)
#   filesystems.nix   disk layout by label (shared with surface-bootstrap)
#   hardware.nix      SP5 quirks: wifi, buttons, panel, power
#   network-aula.nix  school-network proxy dispatcher
#   tablet.nix        Plasma session, greeter, pen/touch apps
#   dev.nix           DAM toolkit (VS Code, JDK 21, Maven, DBeaver)
#   apps.nix          study apps (Obsidian, Zotero, KDE Kirigami apps, Syncthing)
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # linux-surface kernel, IPTS touch/pen, Marvell wifi firmware, thermald, S0ix.
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel

    ../../modules/core
    ../../modules/hardware
    ../../modules/services
    ../../modules/desktop
    ../../modules/programs/lean.nix

    ./filesystems.nix
    ./hardware.nix
    ./network-aula.nix
    ./tablet.nix
    ./dev.nix
    ./apps.nix
  ];

<<<<<<< HEAD
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

=======
>>>>>>> bb95542e9e6c1400db55d062a5cf70c50aedc643
  networking.hostName = "surface";

  # Intel HD 620 only.
  hardware.nvidia.enable = false;

  # --- lean services (the lampp workbench lives on the laptop) ---
  # xampp: off by default (enabled only on laptop)
  modules.services.powertop.enable = true;
  modules.services.smartd.enable = true;
  modules.services.waydroid.enable = true;

  # --- memory: 8GB RAM / 128GB disk ---
  # Keep zram below half of RAM (overrides modules/core/base.nix), plus an 8GB
  # swapfile for suspend/hibernate headroom (created on first activation).
  zramSwap = {
    memoryPercent = lib.mkForce 50;
    memoryMax = lib.mkForce 4294967296; # 4 GiB
  };
  swapDevices = [ { device = "/swapfile"; size = 8192; } ];
  # Hibernate to the swapfile: verify a real hibernate/resume cycle before
  # relying on it.
  boot.resumeDevice = "/dev/disk/by-label/NIXROOT";

  # Daily autoupgrade builds on 8GB RAM / 128GB disk are too heavy for the
  # tablet; deploy from the PC instead.
  system.autoUpgrade.enable = lib.mkForce false;

  # --- keep the 128GB disk from filling up ---
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 5d";
  };
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "26.05";
}
