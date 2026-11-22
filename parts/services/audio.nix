# Audio: PipeWire (replacing PulseAudio).
_: {
  flake.nixosModules.services-audio =
    {
      config,
      lib,
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
