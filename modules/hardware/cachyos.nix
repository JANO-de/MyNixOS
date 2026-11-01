# CachyOS kernel overlay (nix-cachyos-kernel, pinned build). Off on every host today;
# a host opts in with modules.hardware.cachyos.enable (replaces the old cachyos flag in the host table).
{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.hardware.cachyos;
in
{
  options.modules.hardware.cachyos.enable = lib.mkEnableOption "the CachyOS kernel overlay (pinned build)";

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.nix-cachyos-kernel.overlays.pinned ];
  };
}
