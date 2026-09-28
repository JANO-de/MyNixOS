{ config, lib, ... }:

{
  imports = [
    ./options.nix
    ./nvidia.nix
    ./bluetooth.nix
    ./firmware.nix
    ./input.nix
  ];
}
