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
    # On-screen keyboard and other touch-first bits
    ../../modules/desktop/tablet.nix
    ../../modules/programs
  ];

  # The SP5 only has Intel HD 620 graphics, no NVIDIA GPU.
  hardware.nvidia.enable = false;

  networking.hostName = "surface";

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

  # 8GB of RAM: keep the zram ceiling from modules/core below half of physical
  # memory so a swap-heavy workload cannot eat the whole system.
  zramSwap = {
    memoryPercent = lib.mkForce 50;
    memoryMax = lib.mkForce 4294967296; # 4 GiB
  };

  # Home Manager: per-user declarative configuration lives in ../../modules/home
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    # `tablet = true` makes modules/home/niri.nix fill in the touch-only bits
    # of the niri config (digitiser mapping, OSK, 2x output scale).
    extraSpecialArgs = {
      inherit inputs;
      theme = import ../../modules/theme.nix;
      tablet = true;
    };
    users.jano = import ../../modules/home/default.nix;
  };

  system.stateVersion = "26.05";
}
