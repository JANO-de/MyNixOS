# Base profile: always-on configuration (core, generic hardware). Theme lives here
# too but is consumed by path (palette.nix, home.nix), not as a NixOS module.
{ ... }@args:
{
  imports = [
    ./core
    ./hardware
  ];
}
  EOF
