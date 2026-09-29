{ ... }:

{
  imports = [
    ./options.nix
    ./network.nix
    ./audio.nix
    ./printing.nix
    ./ssh.nix
    ./flatpak.nix
    ./autoupgrade.nix
    ./sunshine.nix
    ./xampp.nix
  ];
}
