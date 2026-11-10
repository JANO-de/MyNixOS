# Boot loader (systemd-boot) and compressed in-memory swap (zram).
{ pkgs, lib, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # zram: compressed in-memory swap. RAM-backed, so the effective ceiling is
  # about your RAM size.
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    memoryMax = 17179869184; # 16 GiB
    algorithm = "zstd";
    priority = 100;
  };
}
