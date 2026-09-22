{
  config,
  pkgs,
  lib,
  ...
}: {
  programs.niri = {
    enable = true;
  };

  # Electron apps (vscode, discord, ...) run natively on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Polkit auth agent for the niri session (no NixOS module exists anymore)
  security.polkit.enable = true;

  # GTK icon theme used by the shell (set via dconf since inir is gone)
  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface".icon-theme = "Papirus-Dark";
    }
  ];

  environment.systemPackages = with pkgs; [
    polkit_gnome # launched via spawn-at-startup in the niri config
    xwayland-satellite # niri 25.08+ auto-spawns this on-demand for X11 apps (Steam)
    brightnessctl # Fn brightness keys (XF86MonBrightness*)
    playerctl # Fn media keys (XF86AudioPlay/Next/Prev)
  ];
}