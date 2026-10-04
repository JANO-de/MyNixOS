# Microsoft Surface Pro 5 tablet — lean Plasma 6 (Wayland) host.
# Uses the LEAN program set (modules/programs/lean.nix), not the full one.
#
#   default.nix       identity, memory/swap, services (this file)
#   filesystems.nix   disk layout by label (shared with surface-bootstrap)
#   hardware.nix      SP5 quirks: wifi, buttons, panel, power
#   network-aula.nix  school-network proxy dispatcher
#   tablet.nix        Plasma session, greeter, pen/touch apps
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
  ];

  networking.hostName = "surface";

  # Intel HD 620 only.
  hardware.nvidia.enable = false;

  # --- lean services (the lampp workbench lives on the laptop) ---
  modules.services.xampp.enable = false;
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
    options = "--delete-older-than 14d";
  };
  nix.settings.auto-optimise-store = true;

  system.stateVersion = "26.05";
}
