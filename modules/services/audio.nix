{ config, pkgs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # Explicit default-sink manager. Without it a fresh system can have *no*
    # default output, so volume keys (which go through gsd -> pipewire) appear
    # dead even though GNOME receives the events.
    wireplumber.enable = true;
  };
}
