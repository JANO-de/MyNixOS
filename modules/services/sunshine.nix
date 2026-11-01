# Sunshine: GPU screen-streaming server.
{ config, lib, ... }:

let
  cfg = config.modules.services.sunshine;
in
{
  options.modules.services.sunshine.enable =
    lib.mkEnableOption "Sunshine, the GPU screen-streaming server (pair it with moonlight, e.g. the Surface used as an extra monitor; first pairing at http://<host>:47990)";

  config = lib.mkIf cfg.enable {
    services.sunshine = {
      enable = true;
      openFirewall = true;
    };
    systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  };
}
