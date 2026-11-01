# Hardware module aggregator.
{ ... }@args:
{
  imports = [
    ./bluetooth.nix
    ./firmware.nix
    ./drives.nix
  ];
}
