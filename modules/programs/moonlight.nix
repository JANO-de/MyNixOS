{ config, pkgs, lib, ... }:

# moonlight-qt — fullscreen streaming client. On the Surface this renders a
# Sunshine server's screen (laptop/desktop) so the tablet works as an extra
# monitor.
{
  environment.systemPackages = lib.optionals config.modules.programs.moonlight.enable [ pkgs.moonlight-qt ];
}