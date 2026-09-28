{ lib, ... }:

{
  options.modules.desktop.plasma = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the KDE Plasma 6 desktop and SDDM. Disable on low-RAM/small-disk machines (e.g. tablets) that run niri only.";
    };
  };
}