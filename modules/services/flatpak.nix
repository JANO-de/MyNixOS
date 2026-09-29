{ config, lib, pkgs, ... }:

{
  services.flatpak.enable = true;

  # Register the Flathub repo idempotently so GNOME Software / bazaar find apps
  # out of the box. The pinned nixpkgs flatpak module has no `remotes` option,
  # so this runs at activation. `|| true` keeps an offline activation from
  # failing the switch.
  system.activationScripts.flathub-remote = lib.stringAfter [ "users" ] ''
    ${pkgs.flatpak}/bin/flatpak remote-add --if-not-exists --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
  '';
}
