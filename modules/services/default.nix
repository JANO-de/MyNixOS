# Services module aggregator.
{ ... }@args: {
  imports = [
    ./networking.nix
    ./audio.nix
    ./printing.nix
    ./ssh.nix
    ./flatpak.nix
    ./extras.nix
  ];
}
