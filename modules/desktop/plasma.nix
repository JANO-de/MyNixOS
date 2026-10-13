{ config, lib, ... }:

# Plasma 6 desktop.
#
# The SDDM greeter (and its catppuccin theme) used to live here, but the
# tablet wanted a themed greeter on GNOME too, so the choice of login screen is
# owned by greeter.nix now: Plasma hosts get SDDM either way.
{
  services.xserver.enable = true;
  services.desktopManager.plasma6.enable = config.modules.desktop.plasma.enable;

  # Plasma needs the polkit stack for authorisation dialogs. It used to be
  # pulled in by the GNOME module; keep the Plasma module self-contained so a
  # Plasma-only tablet still gets it.
  security.polkit.enable = lib.mkIf config.modules.desktop.plasma.enable true;
}
