# Audio: PipeWire (replacing PulseAudio).
{ ... }:
{
  flake.nixosModules.services-audio =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    {
      config = lib.mkIf config.modules.services.enable {
        services.pulseaudio.enable = false;
        security.rtkit.enable = true;
        services.pipewire = {
          enable = true;
          alsa.enable = true;
          alsa.support32Bit = true;
          pulse.enable = true;
        };
      };
    };
}
