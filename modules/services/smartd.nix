{ config, lib, ... }:

# smartd — poll the disks' SMART attributes in the background.
#
# A 2017-era NVMe and a spinning laptop drive are old enough that a rising
# reallocated/pending sector count is worth seeing before the device stops
# answering at all. Notifications go to the journal and, on a desktop host, to
# the GUI as a desktop notification; no MTA gets installed on a tablet just to
# deliver mail.
{
  config = lib.mkIf config.modules.services.smartd.enable {
    services.smartd = {
      enable = true;
      autodetect = true;
      notifications.systembus-notify.enable = true;
    };
  };
}
