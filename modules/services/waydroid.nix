# Waydroid: Android in a container on top of the Wayland session.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.services.waydroid;
in
{
  options.modules.services.waydroid.enable =
    lib.mkEnableOption "Waydroid, Android in a container on top of the Wayland session";

  config = lib.mkIf cfg.enable {
    virtualisation.waydroid.enable = true;
    virtualisation.waydroid.package = pkgs.waydroid-nftables;
  };
}
