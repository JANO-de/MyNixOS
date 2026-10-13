# Microsoft Surface Pro 5 (2017, i5-7300U / 8GB / 128GB) — extras on top of
# nixos-hardware's microsoft-surface-pro-intel, which already provides the
# linux-surface kernel, iptsd, redistributable firmware, thermald,
# surface-control and S0ix sleep.
{ pkgs, ... }:

{
  # --- display: Panel Self Refresh blanks the eDP output on this panel ---
  boot.kernelParams = [ "i915.enable_psr=0" "cfg80211.ieee80211_regdom=ES"  ];

  # --- wifi: Marvell 88W8997 (mwifiex_pcie) ---
  # Power saving is flaky on this chip; keep the radio always on.
    networking.networkmanager.wifi.powersave = false;

  # Regulatory domain: without it mwifiex stays on the world domain and 5 GHz
  # channels are passive-only / hidden, so hotspots fall back to 2.4 GHz.
  hardware.wirelessRegulatoryDatabase = true;

  # Phone hotspots often ship a dead DNS relay; always try public DNS first.
  networking.networkmanager.insertNameservers = [ "1.1.1.1" "8.8.8.8" ];

  # The radio ends up soft-blocked after failed activations and nothing clears
  # it; clear it on every boot so it is recoverable without a keyboard.
  systemd.services.rfkill-unblock-wifi = {
    description = "Clear stale wifi soft-blocks left by failed activations";
    before = [ "NetworkManager.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${pkgs.util-linux}/bin/rfkill unblock wifi
    '';
  };

  # mwifiex fails the EAPOL handshake when the AP enforces PMF (802.11w):
  # default PMF OFF for every connection.
  environment.etc."NetworkManager/conf.d/00-surface-pmf.conf".text = ''
    [connection]
    802-11-wireless-security.pmf=0
  '';

  # Some hotspots cap packets below 1500 (seen: 1358); a lower MTU avoids stalls.
  environment.etc."NetworkManager/conf.d/10-wifi-mtu.conf".text = ''
    [connection]
    802-11-wireless.mtu=1340
  '';

  # --- buttons: power, volume up/down (GPIO keys on ACPI MSHW0040) ---
  # soc_button_array's probe runs before the ACPI namespace is ready (udev
  # autoload) and is never retried, leaving the buttons dead. Re-insert the
  # module once udev has settled. (surfacepro3_button failing here is correct.)
  systemd.services.surface-button-bind = {
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    unitConfig.ConditionPathExists = "/sys/bus/acpi/devices/MSHW0040:00";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "-${pkgs.kmod}/bin/modprobe -r soc_button_array";
      ExecStartPost = "${pkgs.kmod}/bin/modprobe soc_button_array";
    };
  };

  # Mark the GPIO button nodes as keyboards so the compositor doesn't drop them.
  services.udev.extraRules = ''
    SUBSYSTEM=="input", KERNEL=="event*", KERNELS=="MSHW0040:00", ENV{ID_INPUT_KEYBOARD}="1"
  '';

  # Plasma owns the power key (powerdevil); long press offers power-off.
  services.logind.settings.Login.HandlePowerKey = "poweroff";

  # --- input ---
  services.libinput.touchpad = {
    tapping = true;
    naturalScrolling = true;
  };
  hardware.sensor.iio.enable = true; # accelerometer -> auto-rotate (iio-sensor-proxy)
    # --- pen + touch (IPTS, handled by iptsd) ---
  services.iptsd = {
    enable = true;
    config = {
      Touchscreen = {
        DisableOnPalm = true;    # no touch while a palm rests on the glass
        DisableOnStylus = true;  # no touch while the pen is hovering/drawing
      };
      Stylus.Disable = false;
    };
  };
  services.udev.packages = [ pkgs.libwacom-surface ];
  environment.systemPackages = [ pkgs.libwacom-surface ];

  # --- storage / security / power ---
  services.fstrim.enable = true;     # TRIM on the 128GB NVMe
  security.tpm2.enable = true;       # Infineon TPM 2.0 (systemd-cryptenroll --tpm2)
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  # The UEFI shows no boot menu of its own, so keep systemd-boot's short.
  boot.loader.timeout = 2;
}