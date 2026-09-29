{ config, pkgs, lib, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      obsidian
      wl-screenrec
      # Required for the surface
      waydroid
      waydroid-helper
    ])
    ++ lib.optionals config.modules.programs.heavy.enable (with pkgs; [
      libreoffice
    ]);
}
