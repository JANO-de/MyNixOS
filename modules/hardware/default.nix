# Hardware module aggregator.
{ ... }@args: {
  imports = [
    ./bluetooth.nix
    ./firmware.nix
    ./nvidia.nix
    ./drives.nix
  ];
}
