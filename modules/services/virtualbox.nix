# VirtualBox: host kernel modules and the user group needed to run VMs.
{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.services.virtualbox;
in
{
  options.modules.services.virtualbox.enable =
    lib.mkEnableOption "VirtualBox host support (kernel modules + vboxusers group)";

  config = lib.mkIf cfg.enable {
    virtualisation.virtualbox.host.enable = true;
    users.users.jano.extraGroups = [ "vboxusers" ];
  };
}
