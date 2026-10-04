# FULL program set: desktop and laptop import this. Everything is on by
# default (see options.nix); individual pieces can still be switched off.
# The Surface imports ./lean.nix instead.
{ ... }:

{
  imports = [
    ./options.nix
    ./terminal.nix
    ./dev.nix
    ./apps.nix
    ./deskflow.nix
    ./moonlight.nix
    ./zathura.nix
    ./gaming.nix
    ./file-manager.nix
  ];
}
