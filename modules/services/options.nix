{ lib, ... }:

{
  options.modules.services.xampp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Wire up the XAMPP workbench (/opt/lampp): system users, FHS compat layer, per-service systemd units and the xampp-panel launcher. Disable on hosts that never installed /opt/lampp (e.g. the Surface tablet), whose xampp units would otherwise fail at every activation.";
    };
  };

  options.modules.services.sunshine = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run the Sunshine GPU screen-streaming server (paired with a moonlight client, e.g. the Surface used as an extra monitor).";
    };
  };

  options.modules.services.powertop = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run powertop's --auto-tune once per boot to shorten device autosuspend timeouts and enable runtime power management. Leaves Wi-Fi power saving alone (see hosts/surface/hardware.nix).";
    };
  };

  options.modules.services.smartd = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Run smartd in the background to poll the disks' SMART attributes, with journal and wall notifications. Catches a failing drive before it disappears.";
    };
  };

  options.modules.services.waydroid = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Waydroid, Android in a container on top of the Wayland session (nftables variant). Needs a kernel with binder/IPC support and a Wayland compositor session to attach to.";
    };
  };
}