{ config, lib, ... }:

# Plasma 6 desktop.
#
# The SDDM greeter (and its catppuccin theme) used to live here, but the
# tablet wanted a themed greeter on GNOME too, so the choice of login screen is
# owned by greeter.nix now: Plasma hosts get SDDM either way.
{
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = config.modules.desktop.plasma.enable;
}
