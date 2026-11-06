# Services module aggregator. Off until a host sets modules.services.enable.
{ lib, ... }:
{
  options.modules.services.enable = lib.mkEnableOption "audio, networking, printing, SSH and Flatpak";

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
  ];
}
