{ config, pkgs, ... }:

{
  programs.niri.enable = true;
  programs.inir = {
    enable = true;
    service.compositor = "niri";
    extraPackages = [
      config.programs.niri.package
      pkgs.glib          # gsettings
      pkgs.ffmpeg         # multimedia backend
    ];
  };

  # Electron apps (vscode, discord, ...) run natively on Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Polkit auth agent for the niri session (no NixOS module exists anymore)
  security.polkit.enable = true;

  # Minimal niri companions (Tide Island provides its own launcher)
  environment.systemPackages = with pkgs; [
    fuzzel
    polkit_gnome # launched via spawn-at-startup in the niri config
    awww # animated wallpaper daemon used by the Tide Island wallpaper picker
    brightnessctl # Fn brightness keys (XF86MonBrightness*)
    playerctl # Fn media keys (XF86AudioPlay/Next/Prev)
  ];
}
