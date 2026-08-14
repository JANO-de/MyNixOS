{ config, pkgs, inputs, lib, ... }:

{
  imports = [ inputs.noctalia.nixosModules.default ];

  programs.niri.enable = true;

  programs.noctalia = {
    enable = true;
    # Enables NetworkManager, Bluetooth, UPower and a power profile service
    # (the first two are already enabled in modules/services).
    recommendedServices.enable = true;
    systemd.enable = true;
  };

  # Qt's GNOME platform theme reads the icon theme from the GSettings key
  # org.gnome.desktop.interface.icon-theme. On NixOS the schema is not
  # discoverable by default (no GSETTINGS_SCHEMA_DIR), so Qt falls back to
  # hicolor and app icons go missing. Make the schema resolvable.
  environment.sessionVariables.GSETTINGS_SCHEMA_DIR =
    let schemaDir = pkg: "${pkg}/share/gsettings-schemas/${pkg.name}/glib-2.0/schemas"; in
    lib.concatStringsSep ":" [
      (schemaDir pkgs.gtk3) # org.gtk.Settings.FileChooser — GTK3 file dialogs abort without it
      (schemaDir pkgs.gsettings-desktop-schemas)
    ];
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".icon-theme = "Papirus-Dark";
    }
  ];

  # Electron apps (vscode, discord, ...) run natively on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Polkit auth agent for the niri session (no NixOS module exists anymore)
  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    polkit_gnome # launched via spawn-at-startup in the niri config
    xwayland-satellite # niri 25.08+ auto-spawns this on-demand for X11 apps (Steam)
    brightnessctl # Fn brightness keys (XF86MonBrightness*)
    playerctl # Fn media keys (XF86AudioPlay/Next/Prev)
  ];
}
