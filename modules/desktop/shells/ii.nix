# ii (ii-p3drovfx) shell module. Opt-in: modules.desktop.shell = "ii".
{ config, lib, pkgs, ... }:
{
  options.modules.desktop.ii.enable = lib.mkEnableOption "ii (ii-p3drovfx) Quickshell shell on Hyprland";

  # Config linking and autostart are wired once the package (pkgs/ii-p3drovfx)
  # exists (I-1). Matugen 4.1.0+ required (nixpkgs has 4.0.0 -> ASK).
}
