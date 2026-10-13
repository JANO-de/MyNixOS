{ config, lib, pkgs, ... }:

# Sunshine — GPU screen/game streaming server. Pair with a moonlight client
# (e.g. moonlight-qt on the Surface) to use that device as an extra screen.
# On Wayland (niri on the laptop/desktop) capture runs through wlgrab; first
# pairing is done in the Web UI at http://<host>:47990.
#
# Thin wrapper around the upstream services.sunshine module, which wires the
# user unit to graphical-session.target (so WAYLAND_DISPLAY is already imported
# into the session when sunshine starts), enables uinput + avahi + udev rules
# for gamepads, and opens the Moonlight port range.
{
  config = lib.mkIf config.modules.services.sunshine.enable {
    services.sunshine = {
      enable = true;
      openFirewall = true;
    };

    # NVENC needs the NVIDIA driver's libcuda.so.1 / libnvidia-encode.so.1,
    # which live outside the Nix store at /run/opengl-driver/lib. Harmless for
    # the software (libx264) encoder and required for hardware encoding.
    systemd.user.services.sunshine.environment.LD_LIBRARY_PATH = "/run/opengl-driver/lib";
  };
}