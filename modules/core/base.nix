{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  programs.mtr.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # zram: compressed in-memory swap, target 16GB. Because zram is RAM-backed,
  # the effective ceiling is ~your RAM size (~15.4G on 16GB).
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    memoryMax = 17179869184; # 16 GiB
    algorithm = "zstd";
    priority = 100;
  };

  swapDevices = [ ];
}
