# Firmware, graphics, input.
{ pkgs, ... }:

{
  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;
  hardware.firmware = [ pkgs.linux-firmware ];

  services.libinput.enable = true;
  hardware.graphics.enable = true;

  # Stable symlinks for hybrid-GPU selection by Hyprland (AQ_DRM_DEVICES).
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="i915", SYMLINK+="dri/igpu"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="amdgpu", SYMLINK+="dri/igpu"
    SUBSYSTEM=="drm", KERNEL=="card[0-9]*", DRIVERS=="nvidia", SYMLINK+="dri/dgpu"
  '';
}
