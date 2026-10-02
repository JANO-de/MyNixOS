{ config, pkgs, lib, ... }:

{
  environment.systemPackages =
    (with pkgs; [
      obsidian
      wl-screenrec
      thunderbird
    ])
    ++ lib.optionals config.modules.programs.heavy.enable (with pkgs; [
      libreoffice
    ]);
}
