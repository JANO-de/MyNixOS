# GNOME on Wayland. Picked for the Surface Pro 5 because it is the most
# tablet-correct desktop in nixpkgs:
#   * built-in on-screen keyboard (pops up on touch focus, no wvkbd needed)
#   * auto screen rotation fed by iio-sensor-proxy (gnome-settings-daemon's
#     orientation plugin)
#   * touch gestures, screen keyboard and fractional scaling out of the box
# Imported by hosts that set `modules.desktop.gnome.enable = true`
# (and niri.enable = false).
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf config.modules.desktop.gnome.enable {
  services.desktopManager.gnome.enable = true;

  # The greeter is chosen by greeter.nix; GDM is the default but a host (e.g.
  # the Surface tablet) can ask for the themed SDDM instead.
  services.displayManager.gdm.enable = config.modules.desktop.displayManager == "gdm";

    # GNOME needs a policy agent and the Polkit stack (niri's module usually
    # provided it; keep it self-contained here so a niri-less tablet still has
    # working authorisation dialogs).
    security.polkit.enable = true;

    # GTK icon theme for the GNOME shell (matches the niri desktop).
    programs.dconf.enable = true;
    programs.dconf.profiles.user.databases = [
      {
        settings."org/gnome/desktop/interface".icon-theme = "Papirus-Dark";
      }
    ]
    # Single owner of custom-keybindings: every module that wants a binding
    # contributes to modules.desktop.customKeybindings, and they are emitted
    # here as one entry. Writing that gsettings key from two places would make
    # the later write silently replace the earlier one.
    ++ lib.optional (
      config.modules.desktop.customKeybindings != [ ]
    ) {
      settings."org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = builtins.toJSON (
        map (
          { name, command, binding, ... }: {
            inherit name command binding;
          }
        ) config.modules.desktop.customKeybindings
      );
    };

    # Accelerometer/gyro feed for auto-rotate. Harmless without a sensor.
    hardware.sensor.iio.enable = true;

    # Fn brightness/media keys are handled by gnome-settings-daemon; these are
    # the ones a Surface Type Cover sends.
    environment.systemPackages = with pkgs; [
      brightnessctl # belt-and-braces CLI for the XF86MonBrightness* keys
      playerctl
    ];
  };
}