# Flatpak, with Flathub registered at activation.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkIf config.modules.services.enable {
    services.flatpak.enable = true;
    system.activationScripts.flathub-remote = lib.stringAfter [ "users" ] ''
      ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    '';
  };
}
