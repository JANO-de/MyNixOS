# Firmware, graphics, input.
_: {
  flake.nixosModules.hardware-firmware =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      config = lib.mkIf config.modules.hardware.enable {
        hardware.enableAllFirmware = true;
        hardware.enableRedistributableFirmware = true;
        hardware.firmware = [ pkgs.linux-firmware ];

        services.libinput.enable = true;
        hardware.graphics.enable = true;

        # Stable /dev/dri/igpu and /dev/dri/dgpu symlinks to pick a GPU by driver (e.g. niri render-drm-device).
        services.udev.extraRules = ''
          SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="i915", SYMLINK+="dri/igpu"
          SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="amdgpu", SYMLINK+="dri/igpu"
          SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="nvidia", SYMLINK+="dri/dgpu"
        '';
      };
    };
}
