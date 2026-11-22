# Services switch: modules.services.enable. Off until a host sets it.
# The services (audio, networking, ssh, ...) are their own modules in this folder.
_: {
  flake.nixosModules.services =
    { lib, ... }:
    {
      options.modules.services.enable = lib.mkEnableOption "audio, networking, printing, SSH, Flatpak and Jellyfin";
    };
}
