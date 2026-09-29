{ config, pkgs, lib, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      obsidian
      wl-screenrec
    ])
    ++ lib.optionals config.modules.programs.heavy.enable (with pkgs; [
      libreoffice
    ]);
}
