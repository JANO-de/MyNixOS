{ lib, ... }:

{
  options.modules.services.xampp = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Wire up the XAMPP workbench (/opt/lampp): system users, FHS compat layer, per-service systemd units and the xampp-panel launcher. Disable on hosts that never installed /opt/lampp (e.g. the Surface tablet), whose xampp units would otherwise fail at every activation.";
    };
  };
}