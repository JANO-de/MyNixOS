# Wake-on-LAN for the wired NIC. Also needs the BIOS setting (ASUS: "Power On By PCI-E"
# or similar, and ErP Ready disabled). The magic packet only works from the LAN.
_: {
  flake.nixosModules.services-wol =
    { pkgs, ... }:
    let
      iface = "enp7s0";
    in
    {
      systemd.services.wol = {
        description = "Enable Wake-on-LAN on ${iface}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-pre.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.ethtool}/bin/ethtool -s ${iface} wol g";
        };
      };
    };
}
