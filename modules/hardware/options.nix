# Host-specific switches for the shared modules in this directory.
# Imported unconditionally by default.nix, so the options exist for every host.
{ lib, ... }:

{
  options.hardware.nvidia = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to set up the NVIDIA driver. Turn this off on hosts without
        an NVIDIA GPU (e.g. the Surface Pro 5, which only has Intel graphics).
      '';
    };
  };
}
