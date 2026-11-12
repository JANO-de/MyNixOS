# Services module aggregator. Off until a host sets modules.services.enable.
{ lib, ... }:
{
  options.modules.services.enable = lib.mkEnableOption "audio, networking, printing, SSH, Flatpak and Jellyfin";

  imports = [
    ./networking.nix
    ./audio.nix
    ./printing.nix
    ./ssh.nix
    ./flatpak.nix
    ./sunshine.nix
    ./waydroid.nix
    ./powertop.nix
    ./smartd.nix
    ./artcraft
    ./virtualbox.nix
    ./qmk.nix
    ./odysseus.nix
    ./tailscale.nix
    ./jellyfin.nix
    ./homepage.nix
    ./artcraft
    ./media-tracker.nix
    ./media-stack.nix
  ];
}
