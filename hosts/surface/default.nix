# Microsoft Surface Pro 5 tablet — lean Plasma 6 (Wayland) host.
# Uses the LEAN program set (modules/programs/lean.nix), not the full one.
#
#   default.nix       identity, memory/swap, services (this file)
#   filesystems.nix   disk layout by label (shared with surface-bootstrap)
#   hardware.nix      SP5 quirks: wifi, buttons, panel, power
#   network-aula.nix  school-network proxy dispatcher
#   tablet.nix        Plasma/SDDM session, greeter OSK, touch cursor
{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    # linux-surface kernel, IPTS touch/pen, Marvell wifi firmware, thermald, S0ix.
    inputs.nixos-hardware.nixosModules.microsoft-surface-pro-intel

    # Denial Wayland session (substituter configured in flake.nix nixConfig).
    inputs.denial.nixosModules.default

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

  # Denial session, selectable at the SDDM login screen (Plasma stays default).
  programs.denial.enable = true;

  # Intel HD 620 only.
  hardware.nvidia.enable = false;

  # Deploys build here and push to the Surface over SSH (see flake mkHost
  # usage). Those paths are unsigned, so the Surface's Nix rejects them with
  # "lacks a signature by a trusted key" unless the copying user is trusted.
  # Same as hosts/desktop/default.nix.
  nix.settings.trusted-users = [ "root" "jano" ];

  # --- lean services (the lampp workbench lives on the laptop) ---
  # xampp: off by default (enabled only on laptop)
  modules.services.powertop.enable = true;
  modules.services.smartd.enable = true;
  modules.services.waydroid.enable = false;

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
  modules.programs.deskflow.role = "client";
  modules.programs.deskflow.serverAddress = "laptop";
}