# LEAN program set for the Surface tablet: CLI essentials, PDF viewer,
# moonlight and deskflow only. No IDEs, office, gaming, chat/browser bundle or
# Nautilus (Plasma brings Dolphin); tablet apps live in hosts/surface/tablet.nix.
{ ... }:

{
  imports = [
    ./options.nix
    ./terminal.nix
    ./deskflow.nix
    ./moonlight.nix
    ./zathura.nix
  ];
}
