# Boot loader (systemd-boot) and compressed in-memory swap (zram).
_: {
  flake.nixosModules.core-boot =
    _:

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
    };
}
