{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    quickshell
  ];

  systemd.user.services.tide-island.wantedBy = lib.mkForce [];
}